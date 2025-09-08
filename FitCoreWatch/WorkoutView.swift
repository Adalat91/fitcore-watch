import SwiftUI

struct WorkoutView: View {
    let workout: Workout
    @EnvironmentObject var workoutManager: WorkoutManager
    @StateObject private var timerManager = TimerManager()
    @State private var isPaused = false
    @State private var currentExerciseIndex = 0
    @State private var currentSetIndex = 0
    @State private var showingTimer = false
    
    var currentExercise: Exercise? {
        guard currentExerciseIndex < workout.exercises.count else { return nil }
        return workout.exercises[currentExerciseIndex]
    }
    
    var currentSet: Set? {
        guard let exercise = currentExercise,
              currentSetIndex < exercise.sets.count else { return nil }
        return exercise.sets[currentSetIndex]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Workout Header
                VStack(spacing: 8) {
                    Text(workout.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        Text("Exercise \(currentExerciseIndex + 1) of \(workout.exercises.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Set \(currentSetIndex + 1) of \(currentExercise?.sets.count ?? 0)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.3))
                .cornerRadius(12)
                
                // Current Exercise
                if let exercise = currentExercise {
                    ExerciseCard(
                        exercise: exercise,
                        currentSetIndex: currentSetIndex,
                        onSetCompleted: completeCurrentSet,
                        onNextSet: nextSet,
                        onPreviousSet: previousSet
                    )
                }
                
                // Timer Section
                VStack(spacing: 12) {
                    HStack {
                        Text("Rest Timer")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(showingTimer ? "Hide" : "Show") {
                            showingTimer.toggle()
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                    
                    if showingTimer {
                        TimerView()
                            .environmentObject(timerManager)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.3))
                .cornerRadius(12)
                
                // Navigation Controls
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button("Previous") {
                            previousExercise()
                        }
                        .buttonStyle(.bordered)
                        .disabled(currentExerciseIndex == 0)
                        
                        Button("Next") {
                            nextExercise()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(currentExerciseIndex >= workout.exercises.count - 1)
                    }
                    
                    Button("Complete Workout") {
                        completeWorkout()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding()
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Keep local timers in sync for any rest/aux timers, and align pause state
            if let start = workoutManager.activeStartDate {
                timerManager.startWorkoutTimer(from: start)
            }
            isPaused = workoutManager.isSessionPaused
            if isPaused { timerManager.pauseWorkoutTimer() }
        }
        .onDisappear {
            timerManager.stopWorkoutTimer()
        }
        .onChange(of: workoutManager.isSessionPaused) { paused in
            isPaused = paused
            if paused {
                timerManager.pauseWorkoutTimer()
            } else {
                timerManager.resumeWorkoutTimer()
            }
        }
    }
    
    // MARK: - Actions
    
    private func completeCurrentSet() {
        guard let exercise = currentExercise,
              currentSetIndex < exercise.sets.count else { return }
        
        workoutManager.completeSet(exerciseId: exercise.id, setId: exercise.sets[currentSetIndex].id)
        
        // Start rest timer
        if let set = currentSet {
            timerManager.startRestTimer(duration: set.restTime)
        }
        
        // Move to next set
        nextSet()
    }
    
    private func nextSet() {
        guard let exercise = currentExercise else { return }
        
        if currentSetIndex < exercise.sets.count - 1 {
            currentSetIndex += 1
        } else {
            // Move to next exercise
            nextExercise()
        }
    }
    
    private func previousSet() {
        if currentSetIndex > 0 {
            currentSetIndex -= 1
        } else if currentExerciseIndex > 0 {
            // Move to previous exercise
            currentExerciseIndex -= 1
            currentSetIndex = workout.exercises[currentExerciseIndex].sets.count - 1
        }
    }
    
    private func nextExercise() {
        if currentExerciseIndex < workout.exercises.count - 1 {
            currentExerciseIndex += 1
            currentSetIndex = 0
        }
    }
    
    private func previousExercise() {
        if currentExerciseIndex > 0 {
            currentExerciseIndex -= 1
            currentSetIndex = 0
        }
    }
    
    private func completeWorkout() {
        workoutManager.completeWorkout()
    }
    
    private func setupWorkout() {
        currentExerciseIndex = 0
        currentSetIndex = 0
    }
    
    private func togglePause() {
        if isPaused {
            workoutManager.resumeSession()
            timerManager.resumeWorkoutTimer()
        } else {
            workoutManager.pauseSession()
            timerManager.pauseWorkoutTimer()
        }
        isPaused.toggle()
    }
}

struct ExerciseCard: View {
    let exercise: Exercise
    let currentSetIndex: Int
    let onSetCompleted: () -> Void
    let onNextSet: () -> Void
    let onPreviousSet: () -> Void
    
    var currentSet: Set? {
        guard currentSetIndex < exercise.sets.count else { return nil }
        return exercise.sets[currentSetIndex]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Exercise Header
            VStack(alignment: .leading, spacing: 8) {
                Text(exercise.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(exercise.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Current Set
            if let set = currentSet {
                VStack(spacing: 12) {
                    HStack {
                        Text("Set \(currentSetIndex + 1)")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if set.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    HStack(spacing: 20) {
                        // Weight
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weight")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(set.weight != nil ? "\(Int(set.weight!)) lbs" : "Body Weight")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        // Reps
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(set.reps)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                    }
                    
                    // Complete Set Button
                    Button(action: onSetCompleted) {
                        HStack {
                            Image(systemName: set.isCompleted ? "checkmark" : "play.fill")
                            Text(set.isCompleted ? "Completed" : "Complete Set")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(set.isCompleted)
                }
                .padding()
                .background(Color.gray.opacity(0.3))
                .cornerRadius(12)
            }
            
            // Set Navigation
            HStack {
                Button("Previous Set") {
                    onPreviousSet()
                }
                .buttonStyle(.bordered)
                .disabled(currentSetIndex == 0)
                
                Spacer()
                
                Button("Next Set") {
                    onNextSet()
                }
                .buttonStyle(.bordered)
                .disabled(currentSetIndex >= exercise.sets.count - 1)
            }
        }
        .padding()
        .background(Color.black)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    WorkoutView(workout: Workout.sample)
        .environmentObject(WorkoutManager())
}

