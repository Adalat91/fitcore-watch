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
        WorkoutTemplate.quickStartTemplates
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
    }
    
    // MARK: - Workout Management
    
    func startWorkout(from template: WorkoutTemplate) {
        let workout = Workout(
            name: template.name,
            exercises: template.exercises,
            notes: template.description
        )
        
        currentWorkout = workout
        isWorkoutActive = true
        
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
        
        healthKitManager.startWorkoutSession()
        watchConnectivityManager.sendMessage(.startWorkout, data: encodeWorkout(workout))
        saveWorkout(workout)
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

