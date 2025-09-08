import SwiftUI

struct ContentView: View {
    @StateObject private var workoutManager = WorkoutManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Workout Tab
            HomeView()
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                    Text("Workout")
                }
                .tag(0)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(1)
        }
        .environmentObject(workoutManager)
        .onAppear {
            workoutManager.requestHealthKitPermissions()
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingQuickStart = false
    @State private var showingTemplates = false
    @State private var showingMyTemplates = false
    @State private var isSyncing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 16) {
                    HStack {
                        // Sync icon with status color - tappable
                        Button(action: {
                            // Manual sync action
                            isSyncing = true
                            workoutManager.syncWithiPhone()
                            
                            // Reset syncing state after a brief delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                isSyncing = false
                            }
                        }) {
                            Image(systemName: isSyncing ? "arrow.triangle.2.circlepath" : "arrow.triangle.2.circlepath")
                                .font(.caption2)
                                .foregroundColor(isSyncing ? .blue : (workoutManager.isSynced ? .green : .red))
                                .rotationEffect(.degrees(isSyncing ? 360 : 0))
                                .animation(isSyncing ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: isSyncing)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isSyncing)
                        
                        Spacer()
                        
                        Text("Workout")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Empty space to balance the layout
                        Color.clear
                            .frame(width: 20, height: 20)
                    }
                    
                    // Start Button
                    Button("Start") {
                        showingQuickStart = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
                
                // Templates Section
                VStack(spacing: 12) {
                    HStack {
                        Text("Templates")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        // My Templates
                        Button(action: {
                            // Navigate to my templates
                            showingMyTemplates = true
                        }) {
                            HStack {
                                Image(systemName: "folder")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                
                                Text("My Templates")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(workoutManager.myTemplatesCount)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Example Templates
                        Button(action: {
                            showingTemplates = true
                        }) {
                            HStack {
                                Image(systemName: "folder")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                
                                Text("Example Templates")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("5")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .background(Color.black)
            .navigationBarHidden(true)
            .onAppear {
                // Auto-sync when landing on this screen
                isSyncing = true
                workoutManager.syncWithiPhone()
                
                // Reset syncing state after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isSyncing = false
                }
            }
            .sheet(isPresented: $showingQuickStart) {
                WorkoutSetupView()
                    .environmentObject(workoutManager)
            }
            .sheet(isPresented: $showingTemplates) {
                TemplatesView()
            }
            .sheet(isPresented: $showingMyTemplates) {
                MyTemplatesView()
            }
        }
    }
}

struct WorkoutCard: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(workout.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(workout.exercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let duration = workout.duration {
                    Text(duration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WorkoutListView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        NavigationView {
            List {
                ForEach(workoutManager.workouts) { workout in
                    NavigationLink(destination: WorkoutView(workout: workout)) {
                        WorkoutRow(workout: workout)
                    }
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New") {
                        // Create new workout
                    }
                }
            }
        }
    }
}

struct WorkoutRow: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if workout.isActive {
                    Text("Active")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            HStack {
                Text("\(workout.exercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let duration = workout.duration {
                    Text(duration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProfileView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        NavigationView {
            List {
                Section("Health Data") {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Heart Rate")
                        Spacer()
                        Text("-- BPM")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("Calories Burned")
                        Spacer()
                        Text("-- cal")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Settings") {
                    Button("Sync with iPhone") {
                        workoutManager.syncWithiPhone()
                    }
                    
                    Button("Export Data") {
                        // Export functionality
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct QuickStartView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Start a Quick Workout")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Choose a workout template to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    ForEach(workoutManager.quickStartTemplates) { template in
                        Button(action: {
                            workoutManager.startWorkout(from: template)
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(template.name)
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    
                                    Text("\(template.exercises.count) exercises")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Quick Start")
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

struct TemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Example Templates")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Choose from pre-built workout templates")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    ForEach(workoutManager.quickStartTemplates) { template in
                        Button(action: {
                            workoutManager.startWorkout(from: template)
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(template.name)
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Text("\(template.exercises.count) exercises")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct MyTemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("My Templates")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                if workoutManager.userTemplates.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        
                        Text("No Custom Templates")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Create templates in the main app to see them here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: 8) {
                            Button("Sync Templates") {
                                workoutManager.requestUserTemplatesFromiPhone()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            
                            Button("Test Connection") {
                                workoutManager.syncWithiPhone()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("Add Test Templates") {
                                workoutManager.addTestTemplates()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(workoutManager.userTemplates) { template in
                            Button(action: {
                                workoutManager.startWorkout(from: template)
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(template.name)
                                            .font(.headline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        Text("\(template.exercises.count) exercises")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WorkoutManager())
}

