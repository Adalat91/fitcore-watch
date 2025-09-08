import Foundation
import SwiftUI
import UserNotifications

class TimerManager: ObservableObject {
    @Published var timerState = TimerState(totalTime: 0)
    @Published var isRunning = false
    @Published var isPaused = false
    
    // Workout session timing
    @Published var workoutStartTime: Date?
    @Published var workoutElapsedTime: TimeInterval = 0
    
    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    private var workoutTimer: Timer?
    
    // MARK: - Timer Control
    
    func startTimer(duration: TimeInterval) {
        stopTimer()
        
        timerState = TimerState(totalTime: duration)
        startTime = Date()
        isRunning = true
        isPaused = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    func pauseTimer() {
        guard isRunning && !isPaused else { return }
        
        timer?.invalidate()
        timer = nil
        
        isPaused = true
        pausedTime = timerState.remainingTime
    }
    
    func resumeTimer() {
        guard isPaused else { return }
        
        startTime = Date()
        isPaused = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        
        isRunning = false
        isPaused = false
        startTime = nil
        pausedTime = 0
    }
    
    func resetTimer() {
        stopTimer()
        timerState = TimerState(totalTime: timerState.totalTime)
    }
    
    func skipTimer() {
        stopTimer()
        timerState.remainingTime = 0
    }
    
    // MARK: - Timer Updates
    
    private func updateTimer() {
        guard let startTime = startTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = max(0, timerState.totalTime - elapsed - pausedTime)
        
        DispatchQueue.main.async {
            self.timerState.remainingTime = remaining
            
            if remaining <= 0 {
                self.timerCompleted()
            }
        }
    }
    
    private func timerCompleted() {
        stopTimer()
        timerState.remainingTime = 0
        
        // Trigger haptic feedback
        triggerHapticFeedback()
        
        // Send notification
        sendTimerCompletionNotification()
    }
    
    // MARK: - Haptic Feedback
    
    private func triggerHapticFeedback() {
        // Use the HapticFeedback struct from Constants.swift for cross-platform compatibility
        HapticFeedback.trigger(.heavy)
        
        // Additional haptic pattern for timer completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            HapticFeedback.trigger(.success)
        }
    }
    
    // MARK: - Notifications
    
    private func sendTimerCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Timer Complete"
        content.body = "Your rest period is over. Ready for the next set?"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "timer_complete",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending timer notification: \(error)")
            }
        }
    }
    
    // MARK: - Preset Timers
    
    func startRestTimer(duration: TimeInterval = 120) {
        startTimer(duration: duration)
    }
    
    func startWorkTimer(duration: TimeInterval = 300) {
        startTimer(duration: duration)
    }
    
    func startWarmupTimer(duration: TimeInterval = 300) {
        startTimer(duration: duration)
    }
    
    // MARK: - Quick Timer Actions
    
    func quickStart1Minute() {
        startTimer(duration: 60)
    }
    
    func quickStart2Minutes() {
        startTimer(duration: 120)
    }
    
    func quickStart3Minutes() {
        startTimer(duration: 180)
    }
    
    func quickStart5Minutes() {
        startTimer(duration: 300)
    }
    
    // MARK: - Workout Session Timing
    
    func startWorkoutTimer() {
        startWorkoutTimer(from: Date())
    }
    
    /// Starts the workout session timer using a provided start date (so it doesn't reset when navigating between views)
    /// - Parameter start: The original workout start time. If nil, uses current Date.
    func startWorkoutTimer(from start: Date?) {
        workoutStartTime = start ?? Date()
        updateWorkoutTimer() // update immediately
        
        workoutTimer?.invalidate()
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateWorkoutTimer()
        }
    }
    
    func stopWorkoutTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
    }
    
    func pauseWorkoutTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
    }
    
    func resumeWorkoutTimer() {
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateWorkoutTimer()
        }
    }
    
    private func updateWorkoutTimer() {
        guard let startTime = workoutStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        DispatchQueue.main.async {
            self.workoutElapsedTime = elapsed
        }
    }
    
    var formattedElapsedTime: String {
        let minutes = Int(workoutElapsedTime) / 60
        let seconds = Int(workoutElapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Timer Extensions

extension TimerManager {
    var formattedTime: String {
        timerState.formattedTime
    }
    
    var progress: Double {
        timerState.progress
    }
    
    var isComplete: Bool {
        timerState.remainingTime <= 0
    }
    
    var timeRemaining: TimeInterval {
        timerState.remainingTime
    }
    
    var totalTime: TimeInterval {
        timerState.totalTime
    }
}
