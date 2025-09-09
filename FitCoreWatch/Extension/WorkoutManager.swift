import Foundation
import SwiftUI
import HealthKit
import WatchConnectivity

@MainActor
class WorkoutManager: NSObject, ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var currentWorkout: Workout?
    @Published var isWorkoutActive = false
    @Published var healthMetrics = HealthMetrics()
    @Published var workoutStats = WorkoutStats()
    @Published var isSynced = false // Sync status with iPhone
    // User-configurable pre-workout options (Watch setup screen)
    @Published var includeWarmupSession: Bool = false
    @Published var restTimersEnabled: Bool = true
    @Published var soundEnabled: Bool = true
    // A session timer that begins when the user lands on the setup screen
    @Published var sessionStartDate: Date?
    // Exercises selected from the Exercises screen before a workout is started
    @Published var draftExercises: [Exercise] = []
    
    // Unified source of truth for any active session start time (pre-workout or in-workout)
    var activeStartDate: Date? {
        currentWorkout?.startTime ?? sessionStartDate
    }

    /// Complete a set by its index within an exercise. Works for both active workout and draft.
    func completeSetByIndex(exerciseId: UUID, setIndex: Int) {
        if var workout = currentWorkout {
            if let eIdx = workout.exercises.firstIndex(where: { $0.id == exerciseId }),
               workout.exercises[eIdx].sets.indices.contains(setIndex) {
                let setId = workout.exercises[eIdx].sets[setIndex].id
                // Reuse existing flow which also syncs and persists
                completeSet(exerciseId: exerciseId, setId: setId)
            }
        } else {
            if let eIdx = draftExercises.firstIndex(where: { $0.id == exerciseId }),
               draftExercises[eIdx].sets.indices.contains(setIndex) {
                draftExercises[eIdx].sets[setIndex].complete()
            }
        }
    }
    
    // Live elapsed time derived from the single source of truth + pause accounting
    var activeElapsedTime: TimeInterval {
        guard let start = activeStartDate else { return 0 }
        var elapsed = Date().timeIntervalSince(start)
        elapsed -= sessionPausedAccumulated
        if let pauseStart = sessionPauseStart {
            elapsed -= Date().timeIntervalSince(pauseStart)
        }
        return max(0, elapsed)
    }
    
    var formattedActiveElapsed: String {
        let total = Int(activeElapsedTime)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    // Global pause state for the session (affects all views)
    @Published var isSessionPaused: Bool = false
    @Published var sessionPauseStart: Date?
    @Published var sessionPausedAccumulated: TimeInterval = 0
    @Published var uiTick: Date = Date()
    private var uiTimer: Timer?
    
    private let dataManager = DataManager()
    private let healthKitManager = HealthKitManager()
    private let watchConnectivityManager = WatchConnectivityManager()
    
    var recentWorkouts: [Workout] {
        workouts
            .filter { !$0.isActive }
            .sorted { $0.startTime > $1.startTime }
            .prefix(5)
            .map { $0 }
    }
    
    var quickStartTemplates: [WorkoutTemplate] {
        // Temporarily disabled; show 0 in UI until examples are enabled again
        return []
    }
    
    @Published var userTemplates: [WorkoutTemplate] = []
    
    var myTemplatesCount: Int {
        userTemplates.count
    }
    
    var todayWorkoutCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return workouts.filter { workout in
            workout.startTime >= today && !workout.isActive
        }.count
    }
    
    var todayDurationMinutes: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let todayWorkouts = workouts.filter { workout in
            workout.startTime >= today && !workout.isActive
        }
        
        return todayWorkouts.reduce(0) { total, workout in
            if let endTime = workout.endTime {
                return total + Int(endTime.timeIntervalSince(workout.startTime) / 60)
            }
            return total
        }
    }
    
    var todayCalories: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let todayWorkouts = workouts.filter { workout in
            workout.startTime >= today && !workout.isActive
        }
        
        return Int(todayWorkouts.reduce(0) { total, workout in
            total + (workout.healthMetrics?.caloriesBurned ?? 0)
        })
    }
    
    override init() {
        super.init()
        setupWatchConnectivity()
        loadWorkouts()
        loadWorkoutStats()
        loadUserTemplates()
        // Restore persisted session start date if any
        if let ts = UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.sessionStartDate) as? TimeInterval {
            self.sessionStartDate = Date(timeIntervalSince1970: ts)
        }
        updateUITimer()
    }
    
    // MARK: - Workout Management
    
    /// Set the pre-workout session start to now, persist it, and reset pause state.
    func setPreWorkoutStartNow() {
        guard currentWorkout == nil else { return }
        sessionStartDate = Date()
        UserDefaults.standard.set(sessionStartDate!.timeIntervalSince1970, forKey: AppConstants.UserDefaultsKeys.sessionStartDate)
        isSessionPaused = false
        sessionPauseStart = nil
        sessionPausedAccumulated = 0
        updateUITimer()
    }

    /// Clear any pre-workout session and its persisted timestamp.
    func clearPreWorkoutSession() {
        guard currentWorkout == nil else { return }
        sessionStartDate = nil
        isSessionPaused = false
        sessionPauseStart = nil
        sessionPausedAccumulated = 0
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.sessionStartDate)
        updateUITimer()
    }

    func startWorkout(from template: WorkoutTemplate) {
        let workout = Workout(
            name: template.name,
            exercises: template.exercises,
            notes: template.description
        )
        
        currentWorkout = workout
        isWorkoutActive = true
        // Transition session timer to real workout start and persist
        sessionStartDate = workout.startTime
        // Reset pause state when transitioning to a real workout
        isSessionPaused = false
        sessionPauseStart = nil
        sessionPausedAccumulated = 0
        UserDefaults.standard.set(workout.startTime.timeIntervalSince1970, forKey: AppConstants.UserDefaultsKeys.sessionStartDate)
        updateUITimer()
        
        // Start health monitoring
        healthKitManager.startWorkoutSession()
        
        // Notify iPhone app
        watchConnectivityManager.sendMessage(.startWorkout, data: encodeWorkout(workout))
        
        // Save workout
        saveWorkout(workout)
    }
    
    func startCustomWorkout(name: String, exercises: [Exercise]) {
        let workout = Workout(name: name, exercises: exercises)
        currentWorkout = workout
        isWorkoutActive = true
        sessionStartDate = workout.startTime
        isSessionPaused = false
        sessionPauseStart = nil
        sessionPausedAccumulated = 0
        
        healthKitManager.startWorkoutSession()
        watchConnectivityManager.sendMessage(.startWorkout, data: encodeWorkout(workout))
        saveWorkout(workout)
        updateUITimer()
    }
    
    func completeWorkout() {
        guard var workout = currentWorkout else { return }
        
        workout.endTime = Date()
        workout.isActive = false
        
        // Stop health monitoring
        healthKitManager.endWorkoutSession()
        
        // Update health metrics
        updateHealthMetrics(for: workout)
        
        // Save completed workout
        saveWorkout(workout)
        
        // Update stats
        updateWorkoutStats(with: workout)
        
        // Notify iPhone app
        watchConnectivityManager.sendMessage(.completeWorkout, data: encodeWorkout(workout))
        
        currentWorkout = nil
        isWorkoutActive = false
        // Clear persisted session start
        sessionStartDate = nil
        isSessionPaused = false
        sessionPauseStart = nil
        sessionPausedAccumulated = 0
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.sessionStartDate)
        updateUITimer()
    }

    // MARK: - Global Pause/Resume for session
    func pauseSession() {
        guard !isSessionPaused else { return }
        isSessionPaused = true
        sessionPauseStart = Date()
        // If a HealthKit workout is active, also pause it
        if isWorkoutActive { healthKitManager.pauseWorkoutSession() }
        updateUITimer()
    }
    
    func resumeSession() {
        guard isSessionPaused else { return }
        if let pauseStart = sessionPauseStart {
            sessionPausedAccumulated += Date().timeIntervalSince(pauseStart)
        }
        sessionPauseStart = nil
        isSessionPaused = false
        if isWorkoutActive { healthKitManager.resumeWorkoutSession() }
        updateUITimer()
    }

    // MARK: - UI Timer driving global refresh
    private func updateUITimer() {
        if activeStartDate != nil {
            if uiTimer == nil {
                uiTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    DispatchQueue.main.async { self?.uiTick = Date() }
                }
            }
        } else {
            uiTimer?.invalidate()
            uiTimer = nil
        }
    }
    
    func pauseWorkout() {
        // Pause health monitoring
        healthKitManager.pauseWorkoutSession()
    }
    
    func resumeWorkout() {
        // Resume health monitoring
        healthKitManager.resumeWorkoutSession()
    }
    
    // MARK: - Exercise Management
    
    /// Add an exercise either to the active workout or to the pre-workout draft list
    /// Creates 2 default sets (12 reps, 2:00 rest) so the user sees set rows immediately.
    func addExercise(name: String, category: String) {
        let defaultSets = [
            Set(weight: nil, reps: 12),
            Set(weight: nil, reps: 12)
        ]
        let ex = Exercise(name: name, category: category, sets: defaultSets)
        if var workout = currentWorkout {
            workout.exercises.append(ex)
            currentWorkout = workout
            saveWorkout(workout)
        } else {
            draftExercises.append(ex)
        }
    }
    
    /// Update a set's weight and reps by exerciseId and set index.
    func updateSet(exerciseId: UUID, setIndex: Int, weight: Double?, reps: Int) {
        if var workout = currentWorkout {
            if let eIdx = workout.exercises.firstIndex(where: { $0.id == exerciseId }),
               workout.exercises[eIdx].sets.indices.contains(setIndex) {
                workout.exercises[eIdx].sets[setIndex].weight = weight
                workout.exercises[eIdx].sets[setIndex].reps = reps
                currentWorkout = workout
                saveWorkout(workout)
            }
        } else {
            if let eIdx = draftExercises.firstIndex(where: { $0.id == exerciseId }),
               draftExercises[eIdx].sets.indices.contains(setIndex) {
                draftExercises[eIdx].sets[setIndex].weight = weight
                draftExercises[eIdx].sets[setIndex].reps = reps
            }
        }
    }
    
    func completeSet(exerciseId: UUID, setId: UUID) {
        guard var workout = currentWorkout else { return }
        
        for exerciseIndex in workout.exercises.indices {
            if workout.exercises[exerciseIndex].id == exerciseId {
                for setIndex in workout.exercises[exerciseIndex].sets.indices {
                    if workout.exercises[exerciseIndex].sets[setIndex].id == setId {
                        workout.exercises[exerciseIndex].sets[setIndex].complete()
                        break
                    }
                }
                break
            }
        }
        
        currentWorkout = workout
        saveWorkout(workout)
        
        // Notify iPhone app
        watchConnectivityManager.sendMessage(.setCompleted, data: encodeWorkout(workout))
    }
    
    func addSet(to exerciseId: UUID, weight: Double?, reps: Int) {
        guard var workout = currentWorkout else { return }
        
        for exerciseIndex in workout.exercises.indices {
            if workout.exercises[exerciseIndex].id == exerciseId {
                let newSet = Set(weight: weight, reps: reps)
                workout.exercises[exerciseIndex].sets.append(newSet)
                break
            }
        }
        
        currentWorkout = workout
        saveWorkout(workout)
    }

    /// Add a set to an exercise for either an active workout or the draft list.
    /// If the exercise already has sets, copy the last set's weight and reps.
    /// Otherwise, use the provided defaults (nil weight, 12 reps).
    func addSetToExercise(exerciseId: UUID, weight: Double? = nil, reps: Int = 12) {
        if var workout = currentWorkout {
            if let idx = workout.exercises.firstIndex(where: { $0.id == exerciseId }) {
                let last = workout.exercises[idx].sets.last
                let newSet = Set(weight: last?.weight ?? weight, reps: last?.reps ?? reps)
                workout.exercises[idx].sets.append(newSet)
                currentWorkout = workout
                saveWorkout(workout)
            }
        } else {
            if let idx = draftExercises.firstIndex(where: { $0.id == exerciseId }) {
                let last = draftExercises[idx].sets.last
                let newSet = Set(weight: last?.weight ?? weight, reps: last?.reps ?? reps)
                var ex = draftExercises[idx]
                ex.sets.append(newSet)
                draftExercises[idx] = ex // trigger @Published update
            }
        }
    }

    /// Remove an exercise by id from either the active workout or the draft list.
    func removeExercise(exerciseId: UUID) {
        if var workout = currentWorkout {
            workout.exercises.removeAll { $0.id == exerciseId }
            currentWorkout = workout
            saveWorkout(workout)
        } else {
            draftExercises.removeAll { $0.id == exerciseId }
        }
    }
    
    // MARK: - Health Kit
    
    func requestHealthKitPermissions() {
        healthKitManager.requestPermissions { [weak self] success in
            if success {
                print("HealthKit permissions granted")
            } else {
                print("HealthKit permissions denied")
            }
        }
    }
    
    private func updateHealthMetrics(for workout: Workout) {
        healthKitManager.getWorkoutMetrics { [weak self] metrics in
            DispatchQueue.main.async {
                self?.healthMetrics = metrics
            }
        }
    }
    
    // MARK: - Data Management
    
    private func loadWorkouts() {
        dataManager.loadWorkouts { [weak self] workouts in
            DispatchQueue.main.async {
                self?.workouts = workouts
            }
        }
    }
    
    private func saveWorkout(_ workout: Workout) {
        dataManager.saveWorkout(workout)
        
        // Update local array
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[index] = workout
        } else {
            workouts.append(workout)
        }
    }
    
    private func loadWorkoutStats() {
        dataManager.loadWorkoutStats { [weak self] stats in
            DispatchQueue.main.async {
                self?.workoutStats = stats
            }
        }
    }
    
    private func loadUserTemplates() {
        dataManager.loadUserTemplates { [weak self] templates in
            DispatchQueue.main.async {
                self?.userTemplates = templates
            }
        }
    }
    
    private func updateWorkoutStats(with workout: Workout) {
        workoutStats.totalWorkouts += 1
        
        if let endTime = workout.endTime {
            let duration = endTime.timeIntervalSince(workout.startTime)
            workoutStats.totalDuration += duration
            workoutStats.averageWorkoutDuration = workoutStats.totalDuration / Double(workoutStats.totalWorkouts)
            
            if duration > workoutStats.longestWorkout {
                workoutStats.longestWorkout = duration
            }
        }
        
        if let calories = workout.healthMetrics?.caloriesBurned {
            workoutStats.totalCalories += calories
        }
        
        dataManager.saveWorkoutStats(workoutStats)
    }
    
    // MARK: - Watch Connectivity
    
    private func setupWatchConnectivity() {
        watchConnectivityManager.delegate = self
    }
    
    func syncWithiPhone() {
        print("Starting sync with iPhone...")
        watchConnectivityManager.sendMessage(.syncData, data: nil)
        // Also request user templates
        requestUserTemplates()
    }
    
    func requestUserTemplatesFromiPhone() {
        print("Manually requesting user templates...")
        requestUserTemplates()
    }
    
    // Debug function to add test templates
    func addTestTemplates() {
        let testTemplates = [
            WorkoutTemplate(
                name: "Test Push Workout",
                exercises: [
                    Exercise(name: "Push-ups", category: "Chest", sets: [
                        Set(weight: nil, reps: 15),
                        Set(weight: nil, reps: 12),
                        Set(weight: nil, reps: 10)
                    ])
                ],
                category: "Upper Body",
                difficulty: .beginner,
                estimatedDuration: 600
            ),
            WorkoutTemplate(
                name: "Test Pull Workout",
                exercises: [
                    Exercise(name: "Pull-ups", category: "Back", sets: [
                        Set(weight: nil, reps: 8),
                        Set(weight: nil, reps: 6),
                        Set(weight: nil, reps: 4)
                    ])
                ],
                category: "Upper Body",
                difficulty: .intermediate,
                estimatedDuration: 600
            )
        ]
        
        DispatchQueue.main.async {
            self.userTemplates = testTemplates
            self.dataManager.saveUserTemplates(testTemplates)
            print("Added \(testTemplates.count) test templates")
        }
    }
    
    // MARK: - Encoding/Decoding
    
    private func encodeWorkout(_ workout: Workout) -> Data? {
        try? JSONEncoder().encode(workout)
    }
    
    private func decodeWorkout(_ data: Data) -> Workout? {
        try? JSONDecoder().decode(Workout.self, from: data)
    }
}

// MARK: - WatchConnectivityDelegate

extension WorkoutManager: WatchConnectivityDelegate {
    func didReceiveMessage(_ message: WatchMessage) {
        switch message.type {
        case .updateWorkout:
            if let data = message.data, let workout = decodeWorkout(data) {
                DispatchQueue.main.async {
                    self.currentWorkout = workout
                }
            }
        case .syncData:
            // Send current workout data to iPhone
            if let workout = currentWorkout {
                watchConnectivityManager.sendMessage(.updateWorkout, data: encodeWorkout(workout))
            }
        case .healthData:
            if let data = message.data, let metrics = try? JSONDecoder().decode(HealthMetrics.self, from: data) {
                DispatchQueue.main.async {
                    self.healthMetrics = metrics
                }
            }
        case .requestData:
            // Request user templates from iPhone
            requestUserTemplates()
        case .userTemplates:
            print("Received user templates message")
            if let data = message.data, let templates = try? JSONDecoder().decode([WorkoutTemplate].self, from: data) {
                print("Successfully decoded \(templates.count) user templates")
                DispatchQueue.main.async {
                    self.userTemplates = templates
                    // Save templates locally
                    self.dataManager.saveUserTemplates(templates)
                }
            } else {
                print("Failed to decode user templates")
            }
        default:
            break
        }
    }
    
    private func requestUserTemplates() {
        print("Requesting user templates from iPhone...")
        // Try both methods
        watchConnectivityManager.sendMessage(.requestData, data: nil)
        
        // Also try UserInfo transfer as backup
        let userInfo = ["request": "userTemplates", "timestamp": Date().timeIntervalSince1970] as [String : Any]
        watchConnectivityManager.sendUserInfo(userInfo)
    }
    
    func syncStatusChanged(_ isSynced: Bool) {
        self.isSynced = isSynced
    }
}

