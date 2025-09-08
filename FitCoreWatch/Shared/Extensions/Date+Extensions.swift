import Foundation

extension Date {
    // MARK: - Date Formatting
    
    /// Format date as time string (e.g., "2:30 PM")
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Format date as date string (e.g., "Jan 15, 2024")
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
    
    /// Format date as full string (e.g., "Jan 15, 2024 at 2:30 PM")
    var fullString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Format date as relative string (e.g., "2 hours ago", "yesterday")
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Format date as short relative string (e.g., "2h ago", "yesterday")
    var shortRelativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    // MARK: - Workout Specific Formatting
    
    /// Format date as workout time (e.g., "2:30 PM")
    var workoutTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Format date as workout date (e.g., "Monday, Jan 15")
    var workoutDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: self)
    }
    
    /// Format date as workout timestamp (e.g., "Jan 15, 2:30 PM")
    var workoutTimestampString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: self)
    }
    
    // MARK: - Duration Formatting
    
    /// Format duration between two dates
    func durationString(to endDate: Date) -> String {
        let interval = endDate.timeIntervalSince(self)
        return interval.durationString
    }
    
    /// Format duration from now
    var durationFromNowString: String {
        let interval = Date().timeIntervalSince(self)
        return interval.durationString
    }
    
    /// Format duration to now
    var durationToNowString: String {
        let interval = self.timeIntervalSince(Date())
        return interval.durationString
    }
    
    // MARK: - Date Calculations
    
    /// Get start of day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// Get end of day
    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }
    
    /// Get start of week
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Get end of week
    var endOfWeek: Date {
        let calendar = Calendar.current
        let startOfWeek = self.startOfWeek
        return calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? self
    }
    
    /// Get start of month
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Get end of month
    var endOfMonth: Date {
        let calendar = Calendar.current
        let startOfMonth = self.startOfMonth
        return calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? self
    }
    
    // MARK: - Date Comparisons
    
    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// Check if date is tomorrow
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    /// Check if date is this week
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// Check if date is this month
    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    /// Check if date is this year
    var isThisYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }
    
    // MARK: - Date Arithmetic
    
    /// Add days to date
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    /// Add hours to date
    func addingHours(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }
    
    /// Add minutes to date
    func addingMinutes(_ minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }
    
    /// Add seconds to date
    func addingSeconds(_ seconds: Int) -> Date {
        Calendar.current.date(byAdding: .second, value: seconds, to: self) ?? self
    }
    
    /// Add time interval to date
    func addingTimeInterval(_ interval: TimeInterval) -> Date {
        self.addingTimeInterval(interval)
    }
    
    // MARK: - Date Components
    
    /// Get year component
    var year: Int {
        Calendar.current.component(.year, from: self)
    }
    
    /// Get month component
    var month: Int {
        Calendar.current.component(.month, from: self)
    }
    
    /// Get day component
    var day: Int {
        Calendar.current.component(.day, from: self)
    }
    
    /// Get hour component
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }
    
    /// Get minute component
    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }
    
    /// Get second component
    var second: Int {
        Calendar.current.component(.second, from: self)
    }
    
    /// Get weekday component (1 = Sunday, 2 = Monday, etc.)
    var weekday: Int {
        Calendar.current.component(.weekday, from: self)
    }
    
    /// Get weekday name
    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
    
    /// Get short weekday name
    var shortWeekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }
    
    /// Get month name
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: self)
    }
    
    /// Get short month name
    var shortMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: self)
    }
}

// MARK: - TimeInterval Extensions

extension TimeInterval {
    /// Format time interval as duration string (e.g., "2:30", "1h 15m")
    var durationString: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    /// Format time interval as short duration string (e.g., "2:30", "1h 15m")
    var shortDurationString: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    /// Format time interval as timer string (e.g., "02:30", "01:15:30")
    var timerString: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// Format time interval as workout duration string (e.g., "2h 30m", "45m", "30s")
    var workoutDurationString: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm", minutes)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

