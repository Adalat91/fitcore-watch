import Foundation

class DataManager {
    private let userDefaults = UserDefaults.standard
    private let workoutsKey = "saved_workouts"
    private let statsKey = "workout_stats"
    
    // MARK: - Workout Management
    
    func saveWorkout(_ workout: Workout) {
        var workouts = loadWorkoutsSync()
        
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[index] = workout
            print("📝 Updated existing workout: \(workout.name) (ID: \(workout.id))")
        } else {
            workouts.append(workout)
            print("💾 Saved new workout: \(workout.name) (ID: \(workout.id))")
        }
        
        saveWorkouts(workouts)
        print("📊 Total workouts saved: \(workouts.count)")
    }
    
    func loadWorkouts(completion: @escaping ([Workout]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let workouts = self.loadWorkoutsSync()
            DispatchQueue.main.async {
                completion(workouts)
            }
        }
    }
    
    private func loadWorkoutsSync() -> [Workout] {
        guard let data = userDefaults.data(forKey: workoutsKey) else { 
            print("📂 No saved workouts found")
            return [] 
        }
        
        do {
            let workouts = try JSONDecoder().decode([Workout].self, from: data)
            print("📂 Loaded \(workouts.count) workouts from storage")
            return workouts
        } catch {
            print("❌ Error loading workouts: \(error)")
            return []
        }
    }
    
    private func saveWorkouts(_ workouts: [Workout]) {
        do {
            let data = try JSONEncoder().encode(workouts)
            userDefaults.set(data, forKey: workoutsKey)
        } catch {
            print("Error saving workouts: \(error)")
        }
    }
    
    func deleteWorkout(_ workout: Workout) {
        var workouts = loadWorkoutsSync()
        workouts.removeAll { $0.id == workout.id }
        saveWorkouts(workouts)
    }
    
    // MARK: - Workout Stats
    
    func saveWorkoutStats(_ stats: WorkoutStats) {
        do {
            let data = try JSONEncoder().encode(stats)
            userDefaults.set(data, forKey: statsKey)
        } catch {
            print("Error saving workout stats: \(error)")
        }
    }
    
    func loadWorkoutStats(completion: @escaping (WorkoutStats) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let stats = self.loadWorkoutStatsSync()
            DispatchQueue.main.async {
                completion(stats)
            }
        }
    }
    
    private func loadWorkoutStatsSync() -> WorkoutStats {
        guard let data = userDefaults.data(forKey: statsKey) else {
            return WorkoutStats()
        }
        
        do {
            let stats = try JSONDecoder().decode(WorkoutStats.self, from: data)
            return stats
        } catch {
            print("Error loading workout stats: \(error)")
            return WorkoutStats()
        }
    }
    
    // MARK: - Health Data
    
    func saveHealthMetrics(_ metrics: HealthMetrics) {
        do {
            let data = try JSONEncoder().encode(metrics)
            userDefaults.set(data, forKey: "health_metrics")
        } catch {
            print("Error saving health metrics: \(error)")
        }
    }
    
    func loadHealthMetrics() -> HealthMetrics? {
        guard let data = userDefaults.data(forKey: "health_metrics") else { return nil }
        
        do {
            let metrics = try JSONDecoder().decode(HealthMetrics.self, from: data)
            return metrics
        } catch {
            print("Error loading health metrics: \(error)")
            return nil
        }
    }
    
    // MARK: - User Templates
    
    func loadUserTemplates(completion: @escaping ([WorkoutTemplate]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let templates = self.loadUserTemplatesSync()
            DispatchQueue.main.async {
                completion(templates)
            }
        }
    }
    
    private func loadUserTemplatesSync() -> [WorkoutTemplate] {
        guard let data = userDefaults.data(forKey: "user_templates") else { return [] }
        
        do {
            let templates = try JSONDecoder().decode([WorkoutTemplate].self, from: data)
            return templates
        } catch {
            print("Error loading user templates: \(error)")
            return []
        }
    }
    
    func saveUserTemplates(_ templates: [WorkoutTemplate]) {
        do {
            let data = try JSONEncoder().encode(templates)
            userDefaults.set(data, forKey: "user_templates")
        } catch {
            print("Error saving user templates: \(error)")
        }
    }
    
    // MARK: - Settings
    
    func saveSetting<T>(_ value: T, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func loadSetting<T>(_ type: T.Type, forKey key: String) -> T? {
        return userDefaults.object(forKey: key) as? T
    }
    
    func loadSetting<T>(_ type: T.Type, forKey key: String, defaultValue: T) -> T {
        return userDefaults.object(forKey: key) as? T ?? defaultValue
    }
    
    // MARK: - Data Export
    
    func exportWorkoutData() -> Data? {
        let workouts = loadWorkoutsSync()
        let stats = loadWorkoutStatsSync()
        
        let exportData = [
            "workouts": workouts,
            "stats": stats,
            "exportDate": Date()
        ] as [String : Any]
        
        do {
            return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        } catch {
            print("Error exporting data: \(error)")
            return nil
        }
    }
    
    // MARK: - Data Cleanup
    
    func cleanupOldData() {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        var workouts = loadWorkoutsSync()
        let originalCount = workouts.count
        
        workouts.removeAll { workout in
            workout.startTime < thirtyDaysAgo && !workout.isActive
        }
        
        if workouts.count != originalCount {
            saveWorkouts(workouts)
            print("Cleaned up \(originalCount - workouts.count) old workouts")
        }
    }
    
    // MARK: - Backup & Restore
    
    func createBackup() -> Data? {
        let workouts = loadWorkoutsSync()
        let stats = loadWorkoutStatsSync()
        
        let backup = BackupData(
            workouts: workouts,
            stats: stats,
            created: Date(),
            version: "1.0"
        )
        
        do {
            return try JSONEncoder().encode(backup)
        } catch {
            print("Error creating backup: \(error)")
            return nil
        }
    }
    
    func restoreFromBackup(_ data: Data) -> Bool {
        do {
            let backup = try JSONDecoder().decode(BackupData.self, from: data)
            
            // Save restored data
            saveWorkouts(backup.workouts)
            saveWorkoutStats(backup.stats)
            
            return true
        } catch {
            print("Error restoring backup: \(error)")
            return false
        }
    }
}

// MARK: - Backup Data Structure

struct BackupData: Codable {
    let workouts: [Workout]
    let stats: WorkoutStats
    let created: Date
    let version: String
}

