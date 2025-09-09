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

enum HomeRoute: Hashable {
    case setup
    case activeWorkout
}

struct HomeView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingQuickStart = false
    @State private var showingTemplates = false
    @State private var showingMyTemplates = false
    @State private var isSyncing = false
    @State private var navPath = NavigationPath()
    @StateObject private var homeTimerManager = TimerManager()
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm" // 12-hour, no AM/PM
        return f
    }()
    
    var body: some View {
        NavigationStack(path: $navPath) {
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
                        
                        // Spacer for symmetry (time moved to overlay)
                        Color.clear.frame(width: 20, height: 20)
                    }
                    
                    // Start or Active Workout
                    // Show Active card if a real workout exists OR a pre-workout session is in progress
                    if let activeWorkout = workoutManager.currentWorkout ?? (workoutManager.sessionStartDate != nil ? Workout(name: "", exercises: []) : nil) {
                        Button(action: {
                            if workoutManager.currentWorkout != nil {
                                navPath.append(HomeRoute.activeWorkout)
                            } else {
                                navPath.append(HomeRoute.setup)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Active Workout")
                                        .font(.subheadline)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                    if !activeWorkout.name.isEmpty {
                                        Text(activeWorkout.name)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.75)
                                    }
                                }
                                Spacer()
                                Text(workoutManager.formattedActiveElapsed)
                                    .font(.caption)
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                    .id(workoutManager.uiTick)
                            }
                            .padding(8)
                            .background(Color.green.opacity(0.25))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green, lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: {
                            workoutManager.setPreWorkoutStartNow()
                            navPath.append(HomeRoute.setup)
                        }) {
                            Text("Start")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(8)
                                .background(Color.blue.opacity(0.25))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue, lineWidth: 1)
                                )
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
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
                                Text("\(workoutManager.quickStartTemplates.count)")
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
                // Ensure timer reflects current active or pre-workout session start
                if let start = workoutManager.activeStartDate {
                    homeTimerManager.startWorkoutTimer(from: start)
                    if workoutManager.isSessionPaused {
                        homeTimerManager.pauseWorkoutTimer()
                    }
                } else {
                    homeTimerManager.stopWorkoutTimer()
                }
            }
            .onChange(of: workoutManager.activeStartDate) { start in
                if let start {
                    homeTimerManager.startWorkoutTimer(from: start)
                    if workoutManager.isSessionPaused {
                        homeTimerManager.pauseWorkoutTimer()
                    }
                } else {
                    homeTimerManager.stopWorkoutTimer()
                }
            }
            .onChange(of: workoutManager.isSessionPaused) { paused in
                if paused {
                    homeTimerManager.pauseWorkoutTimer()
                } else {
                    homeTimerManager.resumeWorkoutTimer()
                }
            }
            // Navigation destinations (modern API)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .setup:
                    WorkoutSetupView()
                        .environmentObject(workoutManager)
                case .activeWorkout:
                    if let wk = workoutManager.currentWorkout {
                        WorkoutView(workout: wk)
                            .environmentObject(workoutManager)
                    } else {
                        WorkoutSetupView()
                            .environmentObject(workoutManager)
                    }
                }
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
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm" // 12-hour, no AM/PM
        return f
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header for Profile with time on the right
                HStack {
                    Spacer()
                    Text("Profile")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
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
            }
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
                // Header
                Text("Example Templates")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                // For now, we intentionally hide example templates and show a clean placeholder
                VStack(spacing: 10) {
                    Image(systemName: "rectangle.on.rectangle")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("Example templates will be available here.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                Spacer(minLength: 0)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
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
                // Header
                Text("My Templates")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if workoutManager.userTemplates.isEmpty {
                    // Clean empty state
                    VStack(spacing: 10) {
                        Image(systemName: "folder")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Text("Your templates will appear here once synced from the FitCore app.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Sync Templates") {
                            workoutManager.requestUserTemplatesFromiPhone()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                } else {
                    // Minimal list of templates
                    List {
                        ForEach(workoutManager.userTemplates) { template in
                            Button(action: {
                                workoutManager.startWorkout(from: template)
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(template.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("\(template.exercises.count) exercises")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "play.circle.fill")
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                }
                Spacer(minLength: 0)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WorkoutManager())
}

