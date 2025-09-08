import SwiftUI

struct ExerciseView: View {
    let exercise: Exercise
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingSetDetails = false
    @State private var selectedSetIndex = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Exercise Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(exercise.category)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(8)
                }
                
                // Exercise Notes
                if let notes = exercise.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                }
                
                // Sets List
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Sets")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(exercise.completedSets)/\(exercise.sets.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                        SetRow(
                            set: set,
                            setNumber: index + 1,
                            isSelected: selectedSetIndex == index,
                            onTap: {
                                selectedSetIndex = index
                                showingSetDetails = true
                            }
                        )
                    }
                }
                
                // Quick Actions
                VStack(spacing: 12) {
                    Button("Add Set") {
                        addNewSet()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Complete Exercise") {
                        completeExercise()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding()
        }
        .navigationTitle("Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSetDetails) {
            SetDetailView(
                set: exercise.sets[selectedSetIndex],
                setNumber: selectedSetIndex + 1,
                onSave: { updatedSet in
                    updateSet(at: selectedSetIndex, with: updatedSet)
                }
            )
        }
    }
    
    // MARK: - Actions
    
    private func addNewSet() {
        let newSet = Set(
            weight: exercise.targetWeight,
            reps: exercise.targetReps ?? 10,
            restTime: exercise.restTime
        )
        
        // Add set to exercise
        // This would need to be implemented in WorkoutManager
        print("Adding new set: \(newSet)")
    }
    
    private func completeExercise() {
        // Mark exercise as completed
        // This would need to be implemented in WorkoutManager
        print("Completing exercise: \(exercise.name)")
    }
    
    private func updateSet(at index: Int, with updatedSet: Set) {
        // Update set in exercise
        // This would need to be implemented in WorkoutManager
        print("Updating set \(index + 1): \(updatedSet)")
    }
}

struct SetRow: View {
    let set: Set
    let setNumber: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set \(setNumber)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 16) {
                        if let weight = set.weight {
                            Text("\(Int(weight)) lbs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Body Weight")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("\(set.reps) reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if set.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(Int(set.restTime / 60)) min rest")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.3))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

public struct SetDetailView: View {
    @State private var set: Set
    let setNumber: Int
    let onSave: (Set) -> Void
    @Environment(\.dismiss) private var dismiss
    
    public init(set: Set, setNumber: Int, onSave: @escaping (Set) -> Void) {
        self._set = State(initialValue: set)
        self.setNumber = setNumber
        self.onSave = onSave
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Set Header
                VStack(spacing: 8) {
                    Text("Set \(setNumber)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Edit set details")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Weight Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        TextField("Weight", value: $set.weight, format: .number)
                            .textFieldStyle(.plain)
                        
                        Text("lbs")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Reps Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reps")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        TextField("Reps", value: $set.reps, format: .number)
                            .textFieldStyle(.plain)
                        
                        Text("reps")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Rest Time
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rest Time")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        TextField("Rest Time", value: $set.restTime, format: .number)
                            .textFieldStyle(.plain)
                        
                        Text("seconds")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextField("Add notes...", text: Binding(
                        get: { set.notes ?? "" },
                        set: { set.notes = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.plain)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Save Changes") {
                        onSave(set)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Complete Set") {
                        set.complete()
                        onSave(set)
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding()
            .navigationTitle("Edit Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ExerciseView(exercise: Exercise.sample)
        .environmentObject(WorkoutManager())
}

