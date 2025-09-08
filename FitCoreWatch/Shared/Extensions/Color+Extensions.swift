import SwiftUI
import UIKit

extension Color {
    // MARK: - FitCore Brand Colors
    
    // Primary Colors
    static let fitcorePrimary = Color(red: 0.4, green: 0.23, blue: 0.72) // Deep Purple
    static let fitcoreSecondary = Color(red: 0.61, green: 0.15, blue: 0.69) // Purple Accent
    
    // Status Colors
    static let fitcoreSuccess = Color(red: 0.3, green: 0.69, blue: 0.31) // Green
    static let fitcoreWarning = Color(red: 1.0, green: 0.6, blue: 0.0) // Orange
    static let fitcoreError = Color(red: 0.96, green: 0.26, blue: 0.21) // Red
    static let fitcoreInfo = Color(red: 0.13, green: 0.59, blue: 0.95) // Blue
    
    // MARK: - Workout Status Colors
    
    /// Active workout color
    static let workoutActive = Color.green
    
    /// Paused workout color
    static let workoutPaused = Color.orange
    
    /// Completed workout color
    static let workoutCompleted = Color.blue
    
    /// Cancelled workout color
    static let workoutCancelled = Color.red
    
    // MARK: - Exercise Category Colors
    
    /// Chest exercises
    static let categoryChest = Color.red
    
    /// Back exercises
    static let categoryBack = Color.blue
    
    /// Shoulder exercises
    static let categoryShoulders = Color.orange
    
    /// Arm exercises
    static let categoryArms = Color.purple
    
    /// Leg exercises
    static let categoryLegs = Color.green
    
    /// Core exercises
    static let categoryCore = Color.yellow
    
    /// Cardio exercises
    static let categoryCardio = Color.pink
    
    // MARK: - Timer Colors
    
    /// Timer running color
    static let timerRunning = Color.blue
    
    /// Timer paused color
    static let timerPaused = Color.orange
    
    /// Timer completed color
    static let timerCompleted = Color.green
    
    /// Timer stopped color
    static let timerStopped = Color.gray
    
    // MARK: - Health Metrics Colors
    
    /// Heart rate color
    static let heartRate = Color.red
    
    /// Calories color
    static let calories = Color.orange
    
    /// Duration color
    static let duration = Color.blue
    
    /// Distance color
    static let distance = Color.green
    
    // MARK: - Background Colors
    
    /// Primary background
    static let fitcoreBackground = Color.black
    
    /// Secondary background
    static let fitcoreSecondaryBackground = Color.gray.opacity(0.2)
    
    /// Tertiary background
    static let fitcoreTertiaryBackground = Color.gray.opacity(0.1)
    
    /// Card background
    static let fitcoreCardBackground = Color.gray.opacity(0.3)
    
    // MARK: - Text Colors
    
    /// Primary text color
    static let fitcorePrimaryText = Color.white
    
    /// Secondary text color
    static let fitcoreSecondaryText = Color.gray
    
    /// Tertiary text color
    static let fitcoreTertiaryText = Color.gray.opacity(0.7)
    
    /// Placeholder text color
    static let fitcorePlaceholderText = Color.gray.opacity(0.5)
    
    // MARK: - Utility Methods
    
    /// Get color for exercise category
    static func forCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "chest":
            return .categoryChest
        case "back":
            return .categoryBack
        case "shoulders":
            return .categoryShoulders
        case "arms":
            return .categoryArms
        case "legs":
            return .categoryLegs
        case "core":
            return .categoryCore
        case "cardio":
            return .categoryCardio
        default:
            return .fitcorePrimary
        }
    }
    
    /// Get color for workout status
    static func forWorkoutStatus(_ isActive: Bool, isCompleted: Bool) -> Color {
        if isCompleted {
            return .workoutCompleted
        } else if isActive {
            return .workoutActive
        } else {
            return .fitcoreSecondaryText
        }
    }
    
    /// Get color for timer status
    static func forTimerStatus(_ isRunning: Bool, isPaused: Bool, isCompleted: Bool) -> Color {
        if isCompleted {
            return .timerCompleted
        } else if isPaused {
            return .timerPaused
        } else if isRunning {
            return .timerRunning
        } else {
            return .timerStopped
        }
    }
    
    /// Get color for set completion status
    static func forSetStatus(_ isCompleted: Bool) -> Color {
        isCompleted ? .fitcoreSuccess : .fitcoreSecondaryText
    }
    
    /// Get color for progress percentage
    static func forProgress(_ progress: Double) -> Color {
        switch progress {
        case 0.0..<0.3:
            return .fitcoreError
        case 0.3..<0.6:
            return .fitcoreWarning
        case 0.6..<0.9:
            return .fitcoreInfo
        case 0.9...1.0:
            return .fitcoreSuccess
        default:
            return .fitcoreSecondaryText
        }
    }
    
    /// Create color with opacity
    func withOpacity(_ opacity: Double) -> Color {
        self.opacity(opacity)
    }
    
    /// Create lighter version of color
    func lighter(by percentage: Double = 0.2) -> Color {
        self.opacity(1.0 - percentage)
    }
    
    /// Create darker version of color
    func darker(by percentage: Double = 0.2) -> Color {
        self.opacity(1.0 + percentage)
    }
}

// MARK: - Color Scheme Extensions

extension ColorScheme {
    /// Check if current color scheme is dark
    var isDark: Bool {
        self == .dark
    }
    
    /// Check if current color scheme is light
    var isLight: Bool {
        self == .light
    }
}

// MARK: - Environment Color Extensions

extension EnvironmentValues {
    /// Get current color scheme
    var colorScheme: ColorScheme {
        get { self[ColorSchemeKey.self] }
        set { self[ColorSchemeKey.self] = newValue }
    }
}

private struct ColorSchemeKey: EnvironmentKey {
    static let defaultValue: ColorScheme = .light
}
