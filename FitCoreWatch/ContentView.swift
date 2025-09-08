import SwiftUI

struct ContentView: View {
    @StateObject private var workoutManager = WorkoutManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // Workouts Tab
            WorkoutListView()
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                    Text("Workouts")
                }
                .tag(1)
            
            // Timer Tab
            TimerView()
                .tabItem {
                    Image(systemName: "timer")
                    Text("Timer")
                }
                .tag(2)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Quick Start Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                            
                            Text("Quick Start")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        Text("Start a workout in seconds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Start Workout") {
                            showingQuickStart = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                    
                    // Recent Workouts
                    if !workoutManager.recentWorkouts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Recent Workouts")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Button("See All") {
                                    // Navigate to workout list
                                }
                                .font(.caption)
                                .foregroundColor(.accentColor)
                            }
                            
                            ForEach(workoutManager.recentWorkouts.prefix(3)) { workout in
                                WorkoutCard(workout: workout)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(12)
                    }
                    
                    // Stats Overview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Stats")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 20) {
                            StatCard(
                                title: "Workouts",
                                value: "\(workoutManager.todayWorkoutCount)",
                                icon: "dumbbell.fill",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Duration",
                                value: "\(workoutManager.todayDurationMinutes) min",
                                icon: "clock.fill",
                                color: .green
                            )
                            
                            StatCard(
                                title: "Calories",
                                value: "\(workoutManager.todayCalories)",
                                icon: "flame.fill",
                                color: .orange
                            )
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("FitCore")
            .sheet(isPresented: $showingQuickStart) {
                QuickStartView()
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

#Preview {
    ContentView()
        .environmentObject(WorkoutManager())
}

