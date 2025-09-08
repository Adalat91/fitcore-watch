import SwiftUI

struct WorkoutSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    
    @State private var includeWarmup = false
    @State private var restTimersEnabled = true
    @State private var soundEnabled = true
    
    @State private var navigateToWorkout = false
    @State private var showingAddExercises = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                // Header with date/time and quick controls
                HStack(spacing: 12) {
                    Text(Date(), style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: { /* pause not applicable yet on setup */ }) {
                        Image(systemName: "pause.fill")
                    }
                    .buttonStyle(.plain)
                    .disabled(true)
                    Button(action: { /* info */ }) {
                        Image(systemName: "info.circle")
                    }
                    .buttonStyle(.plain)
                    .disabled(true)
                }
                .padding(.top, 4)
                
                // Options blocks
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Warmup Session")
                                .font(.headline)
                                .foregroundColor(.orange)
                            Text("Prepare your body before the main workout")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("Warmup", isOn: $includeWarmup)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rest Timers")
                                .font(.headline)
                                .foregroundColor(.blue)
                            Text("Show countdown timers between sets")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("Rest Timers", isOn: $restTimersEnabled)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }
                
                // Main workout options
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Main Workout")
                            .font(.headline)
                        Spacer()
                        Button(action: { showingAddExercises = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle")
                                Text("New")
                            }
                            .font(.caption)
                        }
                    }
                    Toggle("Sound", isOn: $soundEnabled)
                        .toggleStyle(.switch)
                    
                    Button(action: { showingAddExercises = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Exercises")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                // Danger/secondary
                Button(role: .destructive) {
                    dismiss()
                } label: {
                    Text("Cancel Workout")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Spacer(minLength: 4)
                
                // Primary Start button to create the workout and navigate
                NavigationLink(
                    destination: destinationWorkoutView,
                    isActive: $navigateToWorkout,
                    label: { EmptyView() }
                ).hidden()
                
                Button {
                    startWorkout()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Workout")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle("Start")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddExercises) {
                // Reuse templates for adding quickly on watch
                TemplatesView()
                    .environmentObject(workoutManager)
            }
        }
    }
    
    private var destinationWorkoutView: some View {
        Group {
            if let wk = workoutManager.currentWorkout {
                WorkoutView(workout: wk)
                    .environmentObject(workoutManager)
            } else {
                // Fallback (shouldn’t happen)
                Text("Failed to start workout")
            }
        }
    }
    
    private func startWorkout() {
        // Persist user choices to manager for later use
        workoutManager.includeWarmupSession = includeWarmup
        workoutManager.restTimersEnabled = restTimersEnabled
        workoutManager.soundEnabled = soundEnabled
        
        var exercises: [Exercise] = []
        if includeWarmup {
            let warmup = Exercise(
                name: "Warmup",
                category: "Warmup",
                sets: [Set(weight: nil, reps: 10, restTime: 60)]
            )
            exercises.append(warmup)
        }
        
        let name = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        workoutManager.startCustomWorkout(name: "Workout - \(name)", exercises: exercises)
        
        // Navigate to the live workout UI
        navigateToWorkout = true
    }
}

#Preview {
    WorkoutSetupView()
        .environmentObject(WorkoutManager())
}
