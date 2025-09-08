import SwiftUI

struct TimerView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var showingPresets = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Timer Display
            VStack(spacing: 8) {
                Text(timerManager.formattedTime)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(timerManager.isComplete ? .green : .primary)
                
                if timerManager.totalTime > 0 {
                    ProgressView(value: timerManager.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
            }
            
            // Timer Controls
            HStack(spacing: 16) {
                if !timerManager.isRunning {
                    Button("Start") {
                        if timerManager.totalTime > 0 {
                            timerManager.resumeTimer()
                        } else {
                            timerManager.startRestTimer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else if timerManager.isPaused {
                    Button("Resume") {
                        timerManager.resumeTimer()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button("Pause") {
                        timerManager.pauseTimer()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                
                Button("Stop") {
                    timerManager.stopTimer()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            
            // Quick Presets
            VStack(spacing: 12) {
                HStack {
                    Text("Quick Start")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(showingPresets ? "Hide" : "Show") {
                        showingPresets.toggle()
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                
                if showingPresets {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        QuickTimerButton(title: "1 min", duration: 60)
                        QuickTimerButton(title: "2 min", duration: 120)
                        QuickTimerButton(title: "3 min", duration: 180)
                        QuickTimerButton(title: "5 min", duration: 300)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.3))
        .cornerRadius(16)
    }
}

struct QuickTimerButton: View {
    let title: String
    let duration: TimeInterval
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        Button(title) {
            timerManager.startTimer(duration: duration)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

// MARK: - Rest Timer View

struct RestTimerView: View {
    let restTime: TimeInterval
    let onComplete: () -> Void
    @StateObject private var timerManager = TimerManager()
    @State private var isCompleted = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Timer Display
            VStack(spacing: 8) {
                Text("Rest Time")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(timerManager.formattedTime)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(timerManager.isComplete ? .green : .primary)
                
                if timerManager.totalTime > 0 {
                    ProgressView(value: timerManager.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
            }
            
            // Timer Controls
            HStack(spacing: 16) {
                if !timerManager.isRunning {
                    Button("Start Rest") {
                        timerManager.startTimer(duration: restTime)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else if timerManager.isPaused {
                    Button("Resume") {
                        timerManager.resumeTimer()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button("Pause") {
                        timerManager.pauseTimer()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                
                Button("Skip") {
                    timerManager.skipTimer()
                    onComplete()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            
            // Quick Actions
            HStack(spacing: 12) {
                Button("1 min") {
                    timerManager.quickStart1Minute()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("2 min") {
                    timerManager.quickStart2Minutes()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("3 min") {
                    timerManager.quickStart3Minutes()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.3))
        .cornerRadius(16)
        .onAppear {
            timerManager.startTimer(duration: restTime)
        }
        .onChange(of: timerManager.isComplete) { completed in
            if completed && !isCompleted {
                isCompleted = true
                onComplete()
            }
        }
    }
}

// MARK: - Work Timer View

struct WorkTimerView: View {
    let workTime: TimeInterval
    let onComplete: () -> Void
    @StateObject private var timerManager = TimerManager()
    @State private var isCompleted = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Timer Display
            VStack(spacing: 8) {
                Text("Work Time")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(timerManager.formattedTime)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(timerManager.isComplete ? .green : .primary)
                
                if timerManager.totalTime > 0 {
                    ProgressView(value: timerManager.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
            }
            
            // Timer Controls
            HStack(spacing: 16) {
                if !timerManager.isRunning {
                    Button("Start Work") {
                        timerManager.startTimer(duration: workTime)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else if timerManager.isPaused {
                    Button("Resume") {
                        timerManager.resumeTimer()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button("Pause") {
                        timerManager.pauseTimer()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                
                Button("Complete") {
                    timerManager.skipTimer()
                    onComplete()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.3))
        .cornerRadius(16)
        .onAppear {
            timerManager.startTimer(duration: workTime)
        }
        .onChange(of: timerManager.isComplete) { completed in
            if completed && !isCompleted {
                isCompleted = true
                onComplete()
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TimerView()
            .environmentObject(TimerManager())
        
        RestTimerView(restTime: 120) {
            print("Rest completed")
        }
    }
    .padding()
}

