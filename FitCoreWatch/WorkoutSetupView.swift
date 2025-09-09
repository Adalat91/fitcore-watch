import SwiftUI
// Disambiguate our workout Set model from Swift.Set
typealias WorkoutSet = Set

struct WorkoutSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    @StateObject private var timerManager = TimerManager()
    
    // Use manager's source of truth for rest timers
    @State private var restTimersEnabled = true
    @State private var soundEnabled = true
    
    @State private var showingAddExercises = false
    @State private var showingInfo = false
    @State private var isPaused = false
    @State private var showCancelConfirm = false

    // Edit Set Sheet State
    @State private var editingExerciseId: UUID? = nil
    @State private var editingSetIndex: Int = 0
    @State private var tempWeight: Double? = nil
    @State private var tempReps: Int = 12
    @State private var showEditSheet: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    headerSection()
                    optionsSection()
                    workoutSection()
                    
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
            .sheet(isPresented: $showEditSheet) {
                VStack(spacing: 8) {
                    // Title
                    Text("Edit Set")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    // Exercise weight row (compact)
                    HStack(spacing: 8) {
                        Button { if let w = tempWeight { tempWeight = max(0, w - 2.5) } else { tempWeight = 0 } } label: { Image(systemName: "minus") }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        Spacer(minLength: 6)
                        Text(weightString(tempWeight))
                            .font(.body)
                            .monospacedDigit()
                        Text("+LBS")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer(minLength: 6)
                        Button { tempWeight = (tempWeight ?? 0) + 2.5 } label: { Image(systemName: "plus") }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(height: 34)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    // Reps row (compact)
                    HStack(spacing: 8) {
                        Button { tempReps = max(1, tempReps - 1) } label: { Image(systemName: "minus") }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        Spacer(minLength: 6)
                        Text("\(tempReps)")
                            .font(.body)
                            .monospacedDigit()
                        Text("REPS")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer(minLength: 6)
                        Button { tempReps += 1 } label: { Image(systemName: "plus") }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(height: 34)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    // Preview and actions (compact)
                    HStack(spacing: 8) {
                        Text("Next:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("+\(weightString(tempWeight)) lb × \(tempReps)")
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer()
                        Button {
                            if let eId = editingExerciseId {
                                let wDouble = tempWeight
                                workoutManager.updateSet(exerciseId: eId, setIndex: editingSetIndex, weight: wDouble, reps: tempReps)
                            }
                            showEditSheet = false
                        } label: {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.green)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(10)
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
    
    // MARK: - Sections
    @ViewBuilder private func headerSection() -> some View {
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
    }
    
    @ViewBuilder private func optionsSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest Timers")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                Spacer()
                Toggle("Rest Timers", isOn: $workoutManager.restTimersEnabled)
                    .labelsHidden()
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder private func workoutSection() -> some View {
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
            
            // Show added exercises
            VStack(alignment: .leading, spacing: 8) {
                let list = workoutManager.currentWorkout?.exercises ?? workoutManager.draftExercises
                ForEach(list) { ex in
                    ExercisePreviewCard(
                        exercise: ex,
                        restOn: workoutManager.restTimersEnabled,
                        onEdit: { idx in
                            if ex.sets.indices.contains(idx) {
                                self.showEditSet(exerciseId: ex.id, setIndex: idx, current: ex.sets[idx])
                            }
                        }
                    )
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
                        .foregroundColor(.purple)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.purple.opacity(0.25))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
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

    // MARK: - Edit Set Helper
    private func showEditSet(exerciseId: UUID, setIndex: Int, current: WorkoutSet) {
        editingExerciseId = exerciseId
        editingSetIndex = setIndex
        tempWeight = current.weight
        tempReps = current.reps
        showEditSheet = true
    }

    // Format weight without trailing .0, allow .5 increments
    private func weightString(_ value: Double?) -> String {
        guard let v = value else { return "0" }
        if v.truncatingRemainder(dividingBy: 1) == 0 { return String(Int(v)) }
        return String(format: "%.1f", v)
    }
}

// MARK: - Subviews
struct ExercisePreviewCard: View {
    let exercise: Exercise
    let restOn: Bool
    let onEdit: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Exercise name row
            HStack {
                Text(exercise.name)
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
            
            // Set 1
            if exercise.sets.indices.contains(0) {
                Button { onEdit(0) } label: {
                    HStack {
                        Text("1")
                            .font(.caption2)
                        Spacer()
                        Text("\(exercise.sets[0].weight != nil ? String(Int(exercise.sets[0].weight!)) : "--") lb×\(exercise.sets[0].reps)")
                            .font(.caption2)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            // Rest 1
            if restOn {
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
            // Set 2
            if exercise.sets.indices.contains(1) {
                Button { onEdit(1) } label: {
                    HStack {
                        Text("2")
                            .font(.caption2)
                        Spacer()
                        Text("\(exercise.sets[1].weight != nil ? String(Int(exercise.sets[1].weight!)) : "--") lb×\(exercise.sets[1].reps)")
                            .font(.caption2)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            // Rest 2
            if restOn {
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
