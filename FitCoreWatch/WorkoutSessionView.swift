import SwiftUI

struct WorkoutSessionView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @StateObject private var timerManager = TimerManager()
    @State private var warmupEnabled = false
    @State private var restTimersEnabled = false
    @State private var soundEnabled = true
    @State private var showingAddExercises = false
    @State private var showingCancelConfirmation = false
    @State private var workoutStartTime = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Status Bar
            HStack {
                Text(Date().formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "wifi")
                        .font(.caption2)
                    Image(systemName: "battery.75")
                        .font(.caption2)
                    Text("77%")
                        .font(.caption2)
                }
                .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Purple Header
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Date().formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text(timerManager.formattedElapsedTime)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            // Pause workout
                            workoutManager.pauseWorkout()
                        }) {
                            Image(systemName: "pause.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            // Show workout info
                        }) {
                            Image(systemName: "info.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                    }
                    
                    Button(action: {
                        // Finish workout
                        workoutManager.completeWorkout()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.caption)
                            Text("Finish")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.purple)
            
            // Main Content
            ScrollView {
                VStack(spacing: 16) {
                    // Warmup Session Card
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: "dumbbell.fill")
                                .font(.title3)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Warmup Session")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                                
                                Text("Prepare your body before the main workout")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $warmupEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Rest Timers Card
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: "clock.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Rest Timers")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                
                                Text("Show countdown timers between sets")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $restTimersEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Main Workout Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Main Workout")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)
                            
                            Spacer()
                            
                            Toggle("Sound", isOn: $soundEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .purple))
                                .font(.subheadline)
                            
                            Button(action: {
                                showingAddExercises = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.caption)
                                    Text("New")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.2))
                                .foregroundColor(.purple)
                                .cornerRadius(6)
                            }
                        }
                        
                        // Current Exercise Display
                        if let currentWorkout = workoutManager.currentWorkout {
                            VStack(spacing: 8) {
                                Text("Current Exercise")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                if !currentWorkout.exercises.isEmpty {
                                    let currentExercise = currentWorkout.exercises[0] // Simplified for now
                                    Text(currentExercise.name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text("\(currentExercise.sets.count) sets")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("No exercises added")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            showingAddExercises = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                    .font(.headline)
                                Text("Add Exercises")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showingCancelConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "xmark")
                                    .font(.headline)
                                Text("Cancel Workout")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.red)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 2)
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
            }
            .background(Color.gray.opacity(0.05))
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .onAppear {
            startWorkoutTimer()
        }
        .onDisappear {
            stopWorkoutTimer()
        }
        .sheet(isPresented: $showingAddExercises) {
            AddExercisesView()
        }
        .alert("Cancel Workout", isPresented: $showingCancelConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End Workout", role: .destructive) {
                workoutManager.completeWorkout()
            }
        } message: {
            Text("Are you sure you want to end this workout? All progress will be saved.")
        }
    }
    
    private func startWorkoutTimer() {
        workoutStartTime = Date()
        timerManager.startWorkoutTimer()
    }
    
    private func stopWorkoutTimer() {
        timerManager.stopWorkoutTimer()
    }
}

struct AddExercisesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Add Exercises")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Choose exercises to add to your workout")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Exercise categories or quick add options
                VStack(spacing: 12) {
                    ForEach(["Push-ups", "Squats", "Pull-ups", "Lunges", "Plank"], id: \.self) { exerciseName in
                        Button(action: {
                            addExercise(exerciseName)
                        }) {
                            HStack {
                                Text(exerciseName)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addExercise(_ name: String) {
        // Add exercise to current workout
        let exercise = Exercise(name: name, category: "General", sets: [
            Set(weight: nil, reps: 10)
        ])
        
        if var workout = workoutManager.currentWorkout {
            workout.exercises.append(exercise)
            workoutManager.currentWorkout = workout
        }
    }
}

#Preview {
    WorkoutSessionView()
        .environmentObject(WorkoutManager())
}
