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
    // The active rest metadata is persisted in WorkoutManager; mirror it locally for SwiftUI updates
    @State private var activeRestExerciseId: UUID? = nil
    @State private var activeRestAfterSetIndex: Int? = nil
    // Rest editor sheet
    @State private var showRestEditor: Bool = false
    @State private var tempRestSeconds: Int = Int(AppConstants.Timer.defaultRestTime)
    @State private var selectedRestExerciseId: UUID? = nil
    @State private var selectedRestAfterSetIndex: Int? = nil
    @State private var editingActiveRest: Bool = false
    @State private var showDeleteSetConfirm: Bool = false
    
    var body: some View {
        NavigationView {
            mainContentView
        }
    }
    
    // MARK: - Main Content
    @ViewBuilder private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 12) {
                headerSection()
                optionsSection()
                workoutSection()
                actionButtonsSection()
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
            editSetSheet
        }
        .sheet(isPresented: $showRestEditor) {
            restEditorSheet
        }
        .sheet(isPresented: $showingInfo) {
            SessionInfoView()
                .environmentObject(workoutManager)
        }
        .onAppear {
            initializeSession()
        }
        .onDisappear {
            timerManager.stopWorkoutTimer()
        }
        .onChange(of: workoutManager.isSessionPaused) { paused in
            handlePauseStateChange(paused)
        }
    }
    
    // MARK: - Action Buttons Section
    @ViewBuilder private func actionButtonsSection() -> some View {
        VStack(spacing: 6) {
            // Primary action: Finish
            Button {
                handleFinishAction()
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
            .confirmationDialog("Cancel this workout?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
                Button("Cancel Workout", role: .destructive) {
                    handleCancelAction()
                }
                Button("Keep Editing", role: .cancel) {}
            }
        }
    }
    
    // MARK: - Edit Set Sheet
    @ViewBuilder private var editSetSheet: some View {
        VStack(spacing: 8) {
            Text("Edit Set")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            weightControlRow
            repsControlRow
            editSetActionsRow
        }
        .padding(10)
        .onDisappear {
            // Save changes when the sheet is dismissed (including when X is tapped)
            handleSaveChangesOnly()
        }
    }
    
    @ViewBuilder private var weightControlRow: some View {
        HStack(spacing: 6) {
            Button { 
                if let w = tempWeight { 
                    tempWeight = max(0, w - 2.5) 
                } else { 
                    tempWeight = 0 
                } 
            } label: { 
                Image(systemName: "minus") 
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
            
            Spacer(minLength: 4)
            
            Text(weightString(tempWeight))
                .font(.callout)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text("+LBS")
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .layoutPriority(2)
            
            Spacer(minLength: 4)
            
            Button { 
                tempWeight = (tempWeight ?? 0) + 2.5 
            } label: { 
                Image(systemName: "plus") 
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(height: 32)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
    
    @ViewBuilder private var repsControlRow: some View {
        HStack(spacing: 6) {
            Button { 
                tempReps = max(1, tempReps - 1) 
            } label: { 
                Image(systemName: "minus") 
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
            
            Spacer(minLength: 4)
            
            Text("\(tempReps)")
                .font(.callout)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text("REPS")
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .layoutPriority(2)
            
            Spacer(minLength: 4)
            
            Button { 
                tempReps += 1 
            } label: { 
                Image(systemName: "plus") 
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(height: 32)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
    
    @ViewBuilder private var editSetActionsRow: some View {
        HStack(spacing: 8) {
            Button(role: .destructive) {
                showDeleteSetConfirm = true
            } label: {
                Text("Delete")
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
            .confirmationDialog("Delete this set?", isPresented: $showDeleteSetConfirm, titleVisibility: .visible) {
                Button("Delete Set", role: .destructive) {
                    handleDeleteSet()
                }
                Button("Cancel", role: .cancel) {}
            }
            
            Spacer()
            
            Button {
                handleSaveSet()
            } label: {
                Image(systemName: "checkmark")
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.green)
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Rest Editor Sheet
    @ViewBuilder private var restEditorSheet: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Edit Rest")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button("Set All") {
                    workoutManager.updateAllRestTimes(restSeconds: tempRestSeconds)
                    showRestEditor = false
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .font(.caption2)
            }
            
            restTimeControlRow
            
            restEditorActionsRow
        }
        .padding(10)
    }
    
    @ViewBuilder private var restTimeControlRow: some View {
        HStack(spacing: 12) {
            Button { 
                tempRestSeconds = max(15, tempRestSeconds - 15) 
            } label: { 
                Image(systemName: "minus") 
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
            
            Text(formattedSeconds(tempRestSeconds))
                .font(.title3)
                .monospacedDigit()
            
            Button { 
                tempRestSeconds = min(600, tempRestSeconds + 15) 
            } label: { 
                Image(systemName: "plus") 
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
    }
    
    @ViewBuilder private var restEditorActionsRow: some View {
        HStack(spacing: 8) {
            Button("Reset") { 
                tempRestSeconds = Int(AppConstants.Timer.defaultRestTime) 
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Button("Skip", role: .destructive) {
                workoutManager.restTimerManager.skipTimer()
                showRestEditor = false
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Spacer()
            
            Button("Save") {
                handleSaveRest()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
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
                        .foregroundColor(soundEnabled ? Color.blue.opacity(0.7) : .red)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sound")
                .accessibilityValue(soundEnabled ? "On" : "Off")
            }
            
            // Removed large rest timer pill; using only small between-sets timer rows
            
            // Show added exercises
            VStack(alignment: .leading, spacing: 8) {
                ForEach(exerciseList) { ex in
                    ExercisePreviewCard(
                        exercise: ex,
                        restOn: workoutManager.restTimersEnabled,
                        activeRestExerciseId: workoutManager.activeRestExerciseId,
                        activeRestAfterSetIndex: workoutManager.activeRestAfterSetIndex,
                        restTimerManager: workoutManager.restTimerManager,
                        onTapRest: { exerciseId, afterIdx, isActive, currentRestSeconds in
                            selectedRestExerciseId = exerciseId
                            selectedRestAfterSetIndex = afterIdx
                            editingActiveRest = isActive
                            if isActive {
                                // Use remaining time for active timer
                                let remaining = Int(workoutManager.restTimerManager.timeRemaining)
                                tempRestSeconds = max(15, remaining > 0 ? remaining : currentRestSeconds)
                            } else {
                                // Use this set's configured rest time
                                tempRestSeconds = max(15, currentRestSeconds)
                            }
                            showRestEditor = true
                        },
                        onEdit: { idx in
                            if ex.sets.indices.contains(idx) {
                                self.showEditSet(exerciseId: ex.id, setIndex: idx, current: ex.sets[idx])
                            }
                        },
                        onDelete: {
                            workoutManager.removeExercise(exerciseId: ex.id)
                        },
                        onAddSet: {
                            workoutManager.addSetToExercise(exerciseId: ex.id, weight: nil, reps: 12)
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

    // Computed list to ease type-checking
    private var exerciseList: [Exercise] {
        workoutManager.currentWorkout?.exercises ?? workoutManager.draftExercises
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
    
    // MARK: - Helper Methods
    private func initializeSession() {
        if workoutManager.sessionStartDate == nil {
            workoutManager.sessionStartDate = Date()
        }
        timerManager.startWorkoutTimer(from: workoutManager.sessionStartDate)
        isPaused = workoutManager.isSessionPaused
        if isPaused { 
            timerManager.pauseWorkoutTimer() 
        }
    }
    
    private func handlePauseStateChange(_ paused: Bool) {
        isPaused = paused
        if paused {
            timerManager.pauseWorkoutTimer()
        } else {
            timerManager.resumeWorkoutTimer()
        }
    }
    
    private func handleFinishAction() {
        if workoutManager.isWorkoutActive {
            workoutManager.completeWorkout()
        } else {
            workoutManager.clearPreWorkoutSession()
        }
        dismiss()
    }
    
    private func handleCancelAction() {
        if !workoutManager.isWorkoutActive {
            workoutManager.clearPreWorkoutSession()
        }
        dismiss()
    }
    
    private func handleDeleteSet() {
        if let eId = editingExerciseId {
            workoutManager.removeSet(exerciseId: eId, setIndex: editingSetIndex)
        }
        showEditSheet = false
    }
    
    private func handleSaveSet() {
        if let eId = editingExerciseId {
            let wDouble = tempWeight
            workoutManager.updateSet(exerciseId: eId, setIndex: editingSetIndex, weight: wDouble, reps: tempReps)
            withAnimation(.easeInOut(duration: 0.2)) {
                workoutManager.completeSetByIndex(exerciseId: eId, setIndex: editingSetIndex)
            }
            
            if workoutManager.restTimersEnabled {
                var restDuration = AppConstants.Timer.defaultRestTime
                if let ex = exerciseList.first(where: { $0.id == eId }), ex.sets.indices.contains(editingSetIndex) {
                    restDuration = ex.sets[editingSetIndex].restTime
                }
                workoutManager.startRest(exerciseId: eId, afterSetIndex: editingSetIndex, duration: restDuration)
                activeRestExerciseId = workoutManager.activeRestExerciseId
                activeRestAfterSetIndex = workoutManager.activeRestAfterSetIndex
            }
        }
        showEditSheet = false
    }
    
    private func handleSaveChangesOnly() {
        if let eId = editingExerciseId {
            let wDouble = tempWeight
            workoutManager.updateSet(exerciseId: eId, setIndex: editingSetIndex, weight: wDouble, reps: tempReps)
            // Note: NOT calling completeSetByIndex - only saving the changes
        }
        showEditSheet = false
    }
    
    private func handleSaveRest() {
        if let eId = selectedRestExerciseId, let idx = selectedRestAfterSetIndex {
            if editingActiveRest {
                workoutManager.startRest(exerciseId: eId, afterSetIndex: idx, duration: TimeInterval(tempRestSeconds))
            } else {
                workoutManager.updateSetRestTime(exerciseId: eId, setIndex: idx, restSeconds: tempRestSeconds)
            }
        }
        showRestEditor = false
    }

}

// Format seconds as m:ss for use across this file
func formattedSeconds(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%d:%02d", m, s)
}

// MARK: - Subviews
struct ExercisePreviewCard: View {
    let exercise: Exercise
    let restOn: Bool
    let activeRestExerciseId: UUID?
    let activeRestAfterSetIndex: Int?
    @ObservedObject var restTimerManager: TimerManager
    let onTapRest: (_ exerciseId: UUID, _ afterSetIndex: Int, _ isActive: Bool, _ currentRestSeconds: Int) -> Void
    let onEdit: (Int) -> Void
    let onDelete: () -> Void
    let onAddSet: () -> Void
    @State private var showDeleteConfirm = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            nameRow
            setsList
            addSetButton
        }
    }

    // MARK: - Subcomponents
    private var nameRow: some View {
        HStack(spacing: 4) {
            Text(exercise.name)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 4)
            Button(action: { showDeleteConfirm = true }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .regular))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .confirmationDialog("Exercise Options", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Exercise", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) { }
        }
    }

    @ViewBuilder private var setsList: some View {
        ForEach(exercise.sets.indices, id: \.self) { idx in
            setRow(idx: idx)
            if restOn && idx < exercise.sets.count - 1 { restRow(afterSetIndex: idx) }
        }
    }

    @ViewBuilder private func setRow(idx: Int) -> some View {
        let set = exercise.sets[idx]
        Button { onEdit(idx) } label: {
            HStack(spacing: 6) {
                Text("\(idx + 1)")
                    .font(.caption2)
                Spacer(minLength: 6)
                Text("\(weightString(set.weight)) lb×\(set.reps)")
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if set.isCompleted {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func restRow(afterSetIndex idx: Int) -> some View {
        HStack(spacing: 6) {
            let isActive = restTimerManager.isRunning && activeRestExerciseId == exercise.id && activeRestAfterSetIndex == idx
            Image(systemName: "timer")
                .font(.system(size: 10))
                .foregroundColor(isActive ? .blue : .secondary)
            // Show live countdown only for the active rest row
            if isActive {
                Text(restTimerManager.formattedTime)
                    .monospacedDigit()
                    .font(.caption2)
                    .foregroundColor(.blue)
            } else {
                let defaultSeconds = Int(AppConstants.Timer.defaultRestTime)
                let currentSeconds = exercise.sets.indices.contains(idx) ? Int(exercise.sets[idx].restTime) : defaultSeconds
                Text(formattedSeconds(currentSeconds))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 6)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            let isActive = restTimerManager.isRunning && activeRestExerciseId == exercise.id && activeRestAfterSetIndex == idx
            let currentSeconds = exercise.sets.indices.contains(idx) ? Int(exercise.sets[idx].restTime) : Int(AppConstants.Timer.defaultRestTime)
            onTapRest(exercise.id, idx, isActive, currentSeconds)
        }
    }

    private var addSetButton: some View {
        Button(action: onAddSet) {
            HStack {
                Text("Add Set")
                    .font(.caption2)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "plus")
                    .font(.system(size: 12))
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }
}

private func weightString(_ value: Double?) -> String {
    guard let v = value else { return "--" }
    if v.truncatingRemainder(dividingBy: 1) == 0 { return String(Int(v)) }
    return String(format: "%.1f", v)
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
