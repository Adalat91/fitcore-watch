import Foundation
import HealthKit

// MARK: - Workout Models

struct Workout: Identifiable, Codable {
    let id: UUID
    let name: String
    var exercises: [Exercise]
    let startTime: Date
    var endTime: Date?
    var isActive: Bool
    var notes: String?
    var healthMetrics: HealthMetrics?
    
    var duration: String? {
        guard let endTime = endTime else { return nil }
        let interval = endTime.timeIntervalSince(startTime)
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }
    
    var completedSets: Int {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.filter { $0.isCompleted }.count
        }
    }
    
    var progress: Double {
        guard totalSets > 0 else { return 0 }
        return Double(completedSets) / Double(totalSets)
    }
    
    init(name: String, exercises: [Exercise] = [], notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.exercises = exercises
        self.startTime = Date()
        self.endTime = nil
        self.isActive = true
        self.notes = notes
        self.healthMetrics = nil
    }
}

struct Exercise: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: String
    var sets: [Set]
    var notes: String?
    var restTime: TimeInterval
    var targetReps: Int?
    var targetWeight: Double?
    
    var isCompleted: Bool {
        sets.allSatisfy { $0.isCompleted }
    }
    
    var completedSets: Int {
        sets.filter { $0.isCompleted }.count
    }
    
    init(name: String, category: String, sets: [Set] = [], notes: String? = nil, restTime: TimeInterval = 120) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.sets = sets
        self.notes = notes
        self.restTime = restTime
        self.targetReps = nil
        self.targetWeight = nil
    }
}

public struct Set: Identifiable, Codable {
    public let id: UUID
    public var weight: Double?
    public var reps: Int
    public var restTime: TimeInterval
    public var isCompleted: Bool
    public var notes: String?
    public var completedAt: Date?
    
    public init(weight: Double? = nil, reps: Int, restTime: TimeInterval = 120, notes: String? = nil) {
        self.id = UUID()
        self.weight = weight
        self.reps = reps
        self.restTime = restTime
        self.isCompleted = false
        self.notes = notes
        self.completedAt = nil
    }
    
    public mutating func complete() {
        isCompleted = true
        completedAt = Date()
    }
}

// MARK: - Workout Templates

struct WorkoutTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let exercises: [Exercise]
    let category: String
    let difficulty: Difficulty
    let estimatedDuration: TimeInterval
    let description: String?
    
    enum Difficulty: String, CaseIterable, Codable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        
        var color: String {
            switch self {
            case .beginner: return "green"
            case .intermediate: return "orange"
            case .advanced: return "red"
            }
        }
    }
    
    init(name: String, exercises: [Exercise], category: String, difficulty: Difficulty, estimatedDuration: TimeInterval, description: String? = nil) {
        self.id = UUID()
        self.name = name
        self.exercises = exercises
        self.category = category
        self.difficulty = difficulty
        self.estimatedDuration = estimatedDuration
        self.description = description
    }
}

// MARK: - Health Data

struct HealthMetrics: Codable {
    var heartRate: Double?
    var caloriesBurned: Double?
    var activeEnergyBurned: Double?
    var workoutDuration: TimeInterval?
    var averageHeartRate: Double?
    var maxHeartRate: Double?
    var minHeartRate: Double?
    
    init() {
        self.heartRate = nil
        self.caloriesBurned = nil
        self.activeEnergyBurned = nil
        self.workoutDuration = nil
        self.averageHeartRate = nil
        self.maxHeartRate = nil
        self.minHeartRate = nil
    }
}

// MARK: - Workout Statistics

struct WorkoutStats: Codable {
    var totalWorkouts: Int
    var totalDuration: TimeInterval
    var totalCalories: Double
    var averageWorkoutDuration: TimeInterval
    var longestWorkout: TimeInterval
    var mostUsedExercise: String?
    var weeklyGoal: Int
    var weeklyProgress: Int
    
    init() {
        self.totalWorkouts = 0
        self.totalDuration = 0
        self.totalCalories = 0
        self.averageWorkoutDuration = 0
        self.longestWorkout = 0
        self.mostUsedExercise = nil
        self.weeklyGoal = 3
        self.weeklyProgress = 0
    }
    
    var weeklyGoalProgress: Double {
        guard weeklyGoal > 0 else { return 0 }
        return Double(weeklyProgress) / Double(weeklyGoal)
    }
}

// MARK: - Watch Connectivity Messages

enum WatchMessageType: String, Codable {
    case startWorkout = "start_workout"
    case updateWorkout = "update_workout"
    case completeWorkout = "complete_workout"
    case syncData = "sync_data"
    case requestData = "request_data"
    case healthData = "health_data"
    case timerUpdate = "timer_update"
    case setCompleted = "set_completed"
    case userTemplates = "user_templates"
}

struct WatchMessage: Codable {
    let type: WatchMessageType
    let data: Data?
    let timestamp: Date
    
    init(type: WatchMessageType, data: Data? = nil) {
        self.type = type
        self.data = data
        self.timestamp = Date()
    }
}

// MARK: - Timer Models

struct TimerState: Codable {
    var isRunning: Bool
    var remainingTime: TimeInterval
    var totalTime: TimeInterval
    var startTime: Date?
    var endTime: Date?
    
    init(totalTime: TimeInterval) {
        self.isRunning = false
        self.remainingTime = totalTime
        self.totalTime = totalTime
        self.startTime = nil
        self.endTime = nil
    }
    
    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return (totalTime - remainingTime) / totalTime
    }
    
    var formattedTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Extensions

extension Workout {
    static let sample = Workout(
        name: "Push Day",
        exercises: [
            Exercise(name: "Bench Press", category: "Chest", sets: [
                Set(weight: 135, reps: 10),
                Set(weight: 135, reps: 8),
                Set(weight: 135, reps: 6)
            ]),
            Exercise(name: "Overhead Press", category: "Shoulders", sets: [
                Set(weight: 95, reps: 12),
                Set(weight: 95, reps: 10),
                Set(weight: 95, reps: 8)
            ])
        ]
    )
}

extension Exercise {
    static let sample = Exercise(
        name: "Bench Press",
        category: "Chest",
        sets: [
            Set(weight: 135, reps: 10),
            Set(weight: 135, reps: 8),
            Set(weight: 135, reps: 6)
        ]
    )
}

extension WorkoutTemplate {
    // Removed autogenerated example templates. Intentionally left empty.
}

