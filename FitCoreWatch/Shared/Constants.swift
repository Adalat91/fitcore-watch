import Foundation
import SwiftUI
import HealthKit
import UIKit
#if os(watchOS)
import WatchKit
#endif

// MARK: - App Constants

struct AppConstants {
    // MARK: - App Info
    static let appName = "FitCore Watch"
    static let appVersion = "1.0.0"
    static let buildNumber = "1"
    
    // MARK: - Bundle Identifiers
    static let watchAppBundleId = "com.adalat.fitcore.watchkitapp"
    static let companionAppBundleId = "com.adalat.fitcore"
    
    // MARK: - User Defaults Keys
    struct UserDefaultsKeys {
        static let savedWorkouts = "saved_workouts"
        static let workoutStats = "workout_stats"
        static let healthMetrics = "health_metrics"
        static let userSettings = "user_settings"
        static let lastSyncDate = "last_sync_date"
        static let workoutPreferences = "workout_preferences"
        static let sessionStartDate = "session_start_date"
    }
    
    // MARK: - Timer Constants
    struct Timer {
        static let defaultRestTime: TimeInterval = 120 // 2 minutes
        static let defaultWorkTime: TimeInterval = 300 // 5 minutes
        static let defaultWarmupTime: TimeInterval = 300 // 5 minutes
        static let updateInterval: TimeInterval = 1.0 // 1 second
    }
    
    // MARK: - Health Kit Constants
    struct HealthKit {
        static let heartRateUnit = HKUnit(from: "count/min")
        static let caloriesUnit = HKUnit.kilocalorie()
        static let distanceUnit = HKUnit.meter()
        static let timeUnit = HKUnit.second()
    }
    
    // MARK: - Watch Connectivity Constants
    struct WatchConnectivity {
        static let messageKey = "message"
        static let workoutDataKey = "workout_data"
        static let healthDataKey = "health_data"
        static let syncDataKey = "sync_data"
    }
    
    // MARK: - UI Constants
    struct UI {
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 16
        static let shadowRadius: CGFloat = 2
        static let shadowOpacity: Double = 0.1
        static let animationDuration: Double = 0.3
        static let hapticFeedbackDelay: Double = 0.1
    }
    
    // MARK: - Workout Constants
    struct Workout {
        static let maxSetsPerExercise = 20
        static let maxExercisesPerWorkout = 50
        static let maxWorkoutDuration: TimeInterval = 7200 // 2 hours
        static let minRestTime: TimeInterval = 30 // 30 seconds
        static let maxRestTime: TimeInterval = 600 // 10 minutes
    }
    
    // MARK: - Data Constants
    struct Data {
        static let maxWorkoutHistory = 100
        static let maxRecentWorkouts = 10
        static let dataCleanupInterval: TimeInterval = 86400 // 24 hours
        static let backupRetentionDays = 30
    }
}

// MARK: - Color Constants
// Note: Color constants are defined in Color+Extensions.swift

// MARK: - Font Constants

extension Font {
    static let fitcoreLargeTitle = Font.largeTitle.weight(.bold)
    static let fitcoreTitle = Font.title.weight(.semibold)
    static let fitcoreTitle2 = Font.title2.weight(.semibold)
    static let fitcoreTitle3 = Font.title3.weight(.semibold)
    static let fitcoreHeadline = Font.headline.weight(.semibold)
    static let fitcoreSubheadline = Font.subheadline.weight(.medium)
    static let fitcoreBody = Font.body
    static let fitcoreCallout = Font.callout
    static let fitcoreCaption = Font.caption
    static let fitcoreCaption2 = Font.caption2
}

// MARK: - Animation Constants

extension Animation {
    static let fitcoreDefault = Animation.easeInOut(duration: AppConstants.UI.animationDuration)
    static let fitcoreSpring = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let fitcoreBounce = Animation.bouncy(duration: 0.5)
    static let fitcoreSnappy = Animation.snappy(duration: 0.3)
}

// MARK: - Haptic Feedback Constants

struct HapticFeedback {
    static func trigger(_ type: HapticType) {
        #if os(watchOS)
        // Use WKHapticType for watchOS
        switch type {
        case .light:
            WKInterfaceDevice.current().play(.click)
        case .medium:
            WKInterfaceDevice.current().play(.click)
        case .heavy:
            WKInterfaceDevice.current().play(.click)
        case .success:
            WKInterfaceDevice.current().play(.success)
        case .warning:
            WKInterfaceDevice.current().play(.click)
        case .error:
            WKInterfaceDevice.current().play(.failure)
        }
        #else
        // Use UIImpactFeedbackGenerator for iOS
        switch type {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
        #endif
    }
}

enum HapticType {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
}

// MARK: - Notification Constants

struct NotificationConstants {
    static let timerCompleteIdentifier = "timer_complete"
    static let workoutCompleteIdentifier = "workout_complete"
    static let setCompleteIdentifier = "set_complete"
    static let restCompleteIdentifier = "rest_complete"
    
    static let timerCompleteTitle = "Timer Complete"
    static let timerCompleteBody = "Your rest period is over. Ready for the next set?"
    
    static let workoutCompleteTitle = "Workout Complete"
    static let workoutCompleteBody = "Great job! You've completed your workout."
    
    static let setCompleteTitle = "Set Complete"
    static let setCompleteBody = "Set completed! Take a rest before the next one."
}

// MARK: - Error Constants

struct ErrorConstants {
    static let healthKitPermissionDenied = "HealthKit permissions were denied"
    static let workoutSessionFailed = "Failed to start workout session"
    static let dataSaveFailed = "Failed to save workout data"
    static let dataLoadFailed = "Failed to load workout data"
    static let watchConnectivityFailed = "Failed to connect to iPhone"
    static let timerStartFailed = "Failed to start timer"
    static let invalidWorkoutData = "Invalid workout data"
    static let networkError = "Network connection error"
}

// MARK: - Debug Constants

#if DEBUG
struct DebugConstants {
    static let enableLogging = true
    static let enableHapticFeedback = true
    static let enableNotifications = true
    static let mockHealthData = true
    static let mockWorkoutData = true
}
#else
struct DebugConstants {
    static let enableLogging = false
    static let enableHapticFeedback = true
    static let enableNotifications = true
    static let mockHealthData = false
    static let mockWorkoutData = false
}
#endif
