# FitCore Watch App

A standalone Apple Watch app for fitness tracking that will integrate with the main FitCore Flutter app.

## 🚀 Features

- **Workout Tracking** - Log sets, reps, and weights directly on your wrist
- **Rest Timer** - Built-in timer with haptic feedback for rest periods
- **Heart Rate** - Real-time heart rate monitoring during workouts
- **Music Control** - Control music playback without reaching for your phone
- **Always On Display** - Continuous visibility during workouts
- **Standalone Mode** - Work out without your iPhone nearby
- **Data Sync** - Seamless synchronization with main FitCore app

## 📱 Screenshots

*Coming soon - will add screenshots once UI is complete*

## 🛠 Technical Stack

- **SwiftUI** - Modern, declarative UI framework
- **WatchConnectivity** - Communication with iPhone app
- **HealthKit** - Health data integration
- **Core Data** - Local data persistence
- **WorkoutKit** - Workout tracking capabilities

## 🏗 Project Structure

```
fitcore-watch/
├── FitCoreWatch.xcodeproj          # Main Xcode project
├── FitCoreWatch/                   # Watch app target
│   ├── ContentView.swift           # Main app interface
│   ├── WorkoutView.swift           # Workout tracking screen
│   ├── TimerView.swift             # Rest timer interface
│   ├── ExerciseView.swift          # Exercise selection
│   └── Models/                     # Data models
│       ├── Workout.swift           # Workout data model
│       ├── Exercise.swift          # Exercise data model
│       └── Set.swift               # Set data model
├── FitCoreWatch Extension/         # Watch extension
│   ├── WorkoutManager.swift        # Workout management
│   ├── DataManager.swift           # Data persistence
│   ├── WatchConnectivityManager.swift # iPhone communication
│   ├── HealthKitManager.swift      # Health data integration
│   └── TimerManager.swift          # Timer functionality
└── Shared/                         # Shared code
    ├── WorkoutModels.swift         # Shared data models
    ├── Constants.swift             # App constants
    └── Extensions/                  # Swift extensions
        ├── Color+Extensions.swift  # Color utilities
        └── Date+Extensions.swift   # Date utilities
```

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0 or later
- watchOS 10.0 or later
- Apple Watch (Series 4 or later recommended)

### Installation

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd fitcore-watch
   ```

2. Open the project in Xcode:
   ```bash
   open FitCoreWatch.xcodeproj
   ```

3. Select your Apple Watch simulator or device
4. Build and run the project (⌘+R)

### First Run

1. Launch the app on your Apple Watch
2. Grant necessary permissions (HealthKit, Notifications)
3. Start your first workout
4. Experience seamless fitness tracking on your wrist

## 🔧 Development

### Building the Project

```bash
# Build for simulator
xcodebuild -project FitCoreWatch.xcodeproj -scheme FitCoreWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)'

# Build for device
xcodebuild -project FitCoreWatch.xcodeproj -scheme FitCoreWatch -destination 'platform=watchOS,name=Your Watch Name'
```

### Testing

```bash
# Run unit tests
xcodebuild test -project FitCoreWatch.xcodeproj -scheme FitCoreWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)'
```

## 📊 Data Models

### Workout
```swift
struct Workout {
    let id: UUID
    let name: String
    let exercises: [Exercise]
    let startTime: Date
    let endTime: Date?
    let isActive: Bool
}
```

### Exercise
```swift
struct Exercise {
    let id: UUID
    let name: String
    let category: String
    let sets: [Set]
    let notes: String?
}
```

### Set
```swift
struct Set {
    let id: UUID
    let weight: Double?
    let reps: Int
    let restTime: TimeInterval
    let isCompleted: Bool
}
```

## 🔗 Integration with Main App

This watch app communicates with the main FitCore Flutter app through:

1. **WatchConnectivity** - Real-time data synchronization
2. **Shared Data Models** - Consistent data structure
3. **Firebase Backend** - Cloud data storage
4. **HealthKit** - Health data integration

### Communication Protocol

```swift
// Send workout data to iPhone
WatchConnectivityManager.shared.sendWorkoutData(workout)

// Receive workout updates from iPhone
WatchConnectivityManager.shared.onWorkoutUpdate { workout in
    // Update UI with new data
}
```

## 🎨 UI/UX Design

### Design Principles

- **Minimalist** - Clean, uncluttered interface
- **Accessible** - Large touch targets, clear typography
- **Efficient** - Quick access to essential features
- **Intuitive** - Natural navigation patterns

### Color Scheme

- **Primary**: Deep Purple (#673AB7)
- **Secondary**: Purple Accent (#9C27B0)
- **Success**: Green (#4CAF50)
- **Warning**: Orange (#FF9800)
- **Error**: Red (#F44336)

## 📱 Supported Devices

- Apple Watch Series 4 and later
- watchOS 10.0 and later
- Requires iPhone with iOS 17.0 and later

## 🔒 Privacy & Security

- All health data is stored locally on device
- Data sync is encrypted end-to-end
- No personal data is shared with third parties
- Full compliance with Apple's privacy guidelines

## 🚀 Roadmap

### Version 1.0 (Current)
- [x] Basic workout tracking
- [x] Rest timer functionality
- [x] Heart rate monitoring
- [x] Music control
- [x] Always On Display support

### Version 1.1 (Planned)
- [ ] Advanced analytics
- [ ] Custom workout creation
- [ ] Social features
- [ ] Apple Fitness+ integration

### Version 2.0 (Future)
- [ ] AI-powered workout suggestions
- [ ] Advanced health metrics
- [ ] Integration with other fitness apps
- [ ] Apple Watch Ultra optimizations

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Documentation**: [Wiki](https://github.com/your-username/fitcore-watch/wiki)
- **Issues**: [GitHub Issues](https://github.com/your-username/fitcore-watch/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/fitcore-watch/discussions)

## 🙏 Acknowledgments

- Apple for the amazing watchOS platform
- The Flutter team for the main app framework
- The fitness community for inspiration and feedback

---

**Built with ❤️ for the fitness community**

