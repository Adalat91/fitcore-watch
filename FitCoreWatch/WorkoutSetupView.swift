import SwiftUI

struct WorkoutSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    @StateObject private var timerManager = TimerManager()
    
    @State private var includeWarmup = false
    @State private var restTimersEnabled = true
    @State private var soundEnabled = true
    
    @State private var showingAddExercises = false
    @State private var showCancelConfirm = false
    
    var body: some View {
        NavigationView {
            ScrollView {
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
                            Text("Warmup")
                                .font(.headline)
                                .foregroundColor(.orange)
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
                    HStack(spacing: 6) {
                        Text("Workout")
                            .font(.subheadline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer()
                        Button(action: {
                            soundEnabled.toggle()
                            HapticFeedback.trigger(.light)
                        }) {
                            Image(systemName: soundEnabled ? "bell.fill" : "bell.slash.fill")
                                .font(.caption)
                                .foregroundColor(soundEnabled ? .secondary : .red)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Sound")
                        .accessibilityValue(soundEnabled ? "On" : "Off")
                    }
                    
                    Button(action: { showingAddExercises = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Add Exercises")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                            Image(systemName: "plus")
                                .font(.body)
                                .foregroundColor(.accentColor)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                // Primary action: Finish
                Button {
                    if workoutManager.isWorkoutActive {
                        workoutManager.completeWorkout()
                    }
                    dismiss()
                } label: {
                    Text("Finish")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.small)

                // Danger/secondary
                Button(role: .destructive) {
                    showCancelConfirm = true
                } label: {
                    Text("Cancel Workout")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 6)
                .confirmationDialog("Cancel this workout?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
                    Button("Cancel Workout", role: .destructive) {
                        dismiss()
                    }
                    Button("Keep Editing", role: .cancel) {}
                }
                
                Spacer(minLength: 4)
                }
                .padding()
            }
            .navigationTitle(timerManager.formattedElapsedTime)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddExercises) {
                // Reuse templates for adding quickly on watch
                TemplatesView()
                    .environmentObject(workoutManager)
            }
            .onAppear {
                timerManager.startWorkoutTimer()
            }
            .onDisappear {
                timerManager.stopWorkoutTimer()
            }
        }
    }
    
    // No explicit start button; the workout will be started from another UI action.
}

#Preview {
    WorkoutSetupView()
        .environmentObject(WorkoutManager())
}
