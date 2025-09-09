import SwiftUI

struct WorkoutSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    @StateObject private var timerManager = TimerManager()
    
    @State private var restTimersEnabled = true
    @State private var soundEnabled = true
    
    @State private var showingAddExercises = false
    @State private var showingInfo = false
    @State private var isPaused = false
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
                    Button(action: togglePause) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    }
                    .buttonStyle(.plain)
                    Button(action: { showingInfo = true }) {
                        Image(systemName: "info.circle")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
                
                // Options blocks
                VStack(alignment: .leading, spacing: 8) {
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
                    
                    // Show added exercises (current workout if active, else draft list)
                    VStack(alignment: .leading, spacing: 8) {
                        let list = workoutManager.currentWorkout?.exercises ?? workoutManager.draftExercises
                        ForEach(list) { ex in
                            VStack(alignment: .leading, spacing: 6) {
                                // Exercise name row
                                HStack {
                                    Text(ex.name)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "ellipsis")
                                        .font(.caption2)
                                }
                                .padding(8)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(10)

                                // Two default sets preview
                                let sets = ex.sets
                                if sets.indices.contains(0) {
                                    HStack {
                                        Text("1")
                                            .font(.caption2)
                                        Spacer()
                                        Text(sets[0].weight != nil ? "\(Int(sets[0].weight!)) lb×\(sets[0].reps)" : "\(sets[0].reps) reps")
                                            .font(.caption2)
                                    }
                                    .padding(8)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(10)
                                }
                                HStack {
                                    Image(systemName: "timer")
                                        .font(.caption2)
                                    Spacer()
                                    Text("2:00")
                                        .font(.caption2)
                                }
                                .padding(8)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(10)
                                if sets.indices.contains(1) {
                                    HStack {
                                        Text("2")
                                            .font(.caption2)
                                        Spacer()
                                        Text(sets[1].weight != nil ? "\(Int(sets[1].weight!)) lb×\(sets[1].reps)" : "\(sets[1].reps) reps")
                                            .font(.caption2)
                                    }
                                    .padding(8)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(10)
                                }
                                HStack {
                                    Image(systemName: "timer")
                                        .font(.caption2)
                                    Spacer()
                                    Text("2:00")
                                        .font(.caption2)
                                }
                                .padding(8)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(10)
                            }
                        }
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
                .tint(.orange)
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
                        // Only clear the pre-workout session if a real workout hasn't started
                        if !workoutManager.isWorkoutActive {
                            workoutManager.sessionStartDate = nil
                        }
                        dismiss()
                    }
                    Button("Keep Editing", role: .cancel) {}
                }
                
                Spacer(minLength: 4)
                }
                .padding()
            }
            .navigationTitle(workoutManager.formattedActiveElapsed)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddExercises) {
                ExercisesView()
                    .environmentObject(workoutManager)
            }
            .sheet(isPresented: $showingInfo) {
                SessionInfoView()
                    .environmentObject(workoutManager)
            }
            .onAppear {
                // Initialize a session timer if one isn't already running
                if workoutManager.sessionStartDate == nil {
                    workoutManager.sessionStartDate = Date()
                }
                timerManager.startWorkoutTimer(from: workoutManager.sessionStartDate)
                // Align local pause state with global state
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
    }
    
    // No explicit start button; the workout will be started from another UI action.
    private func togglePause() {
        if isPaused {
            // resume globally
            workoutManager.resumeSession()
            timerManager.resumeWorkoutTimer()
        } else {
            // pause globally
            workoutManager.pauseSession()
            timerManager.pauseWorkoutTimer()
        }
        isPaused.toggle()
    }
}

// Simple info sheet for the session
struct SessionInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        NavigationView {
            List {
                Section("Session") {
                    HStack {
                        Text("Started")
                        Spacer()
                        Text(startedText)
                            .foregroundColor(.secondary)
                    }
                }
                Section("Options") {
                    HStack { Text("Rest Timers"); Spacer(); Text(workoutManager.restTimersEnabled ? "On" : "Off").foregroundColor(.secondary) }
                    HStack { Text("Sound"); Spacer(); Text(workoutManager.soundEnabled ? "On" : "Off").foregroundColor(.secondary) }
                }
            }
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var startedText: String {
        if let start = workoutManager.activeStartDate { return start.formatted(date: .abbreviated, time: .shortened) }
        return "—"
    }
    private var elapsedText: String { "" }
}

// Fallback removed: using the real ExercisesView from FitCoreWatch/ExercisesView.swift

#Preview {
    WorkoutSetupView()
        .environmentObject(WorkoutManager())
}
