import Foundation
import SwiftUI

struct WalkRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let breedUsed: String
    let startWeather: WeatherSnapshot
    let endWeather: WeatherSnapshot?
    let warningsEncountered: [WarningType]
    let safetyLevel: SafetyLevel
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        duration: TimeInterval,
        breedUsed: String,
        startWeather: WeatherSnapshot,
        endWeather: WeatherSnapshot? = nil,
        warningsEncountered: [WarningType] = [],
        safetyLevel: SafetyLevel
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.breedUsed = breedUsed
        self.startWeather = startWeather
        self.endWeather = endWeather
        self.warningsEncountered = warningsEncountered
        self.safetyLevel = safetyLevel
    }
}

struct WeatherSnapshot: Codable {
    let temperature: Double
    let humidity: Double
    let windSpeed: Double
    let weatherCondition: String
    let timestamp: Date
    
    init(from weatherResponse: WeatherResponse) {
        self.temperature = weatherResponse.main.temp
        self.humidity = Double(weatherResponse.main.humidity)
        self.windSpeed = weatherResponse.wind?.speed ?? 0.0
        self.weatherCondition = weatherResponse.weather.first?.main ?? "Unknown"
        self.timestamp = Date()
    }
    
    init(temperature: Double, humidity: Double, windSpeed: Double, weatherCondition: String, timestamp: Date = Date()) {
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.weatherCondition = weatherCondition
        self.timestamp = timestamp
    }
}

enum WalkState {
    case notWalking
    case walking
    case paused
    case completed
}

class WalkManager: ObservableObject {
    @Published var walkState: WalkState = .notWalking
    @Published var walkDuration: TimeInterval = 0
    @Published var currentWalk: WalkRecord?
    @Published var walkHistory: [WalkRecord] = []
    @Published var warningsEncountered: [WarningType] = []
    
    // Streak tracking
    @AppStorage("currentStreak") private var currentStreak = 0
    @AppStorage("longestStreak") private var longestStreak = 0
    @AppStorage("lastWalkDate") private var lastWalkDate: String = ""
    
    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    
    init() {
        loadWalkHistory()
    }
    
    // MARK: - Streak Properties
    var streakCount: Int {
        return currentStreak
    }
    
    var bestStreak: Int {
        return longestStreak
    }
    
    func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let lastDate = formatter.date(from: lastWalkDate) {
            let dayDifference = Calendar.current.dateComponents([.day], from: lastDate, to: today).day ?? 0
            
            if dayDifference == 0 {
                // Same day, don't change streak
            } else if dayDifference == 1 {
                // Next day, increment streak
                currentStreak += 1
            } else {
                // Missed day(s), reset streak
                currentStreak = 1
            }
        } else {
            // First walk ever
            currentStreak = 1
        }
        
        lastWalkDate = formatter.string(from: today)
        longestStreak = max(longestStreak, currentStreak)
    }
    
    func startWalk(breed: DogBreed, startWeather: WeatherResponse) {
        walkState = .walking
        startTime = Date()
        pausedTime = 0
        walkDuration = 0
        warningsEncountered = []
        
        let weatherSnapshot = WeatherSnapshot(from: startWeather)
        currentWalk = WalkRecord(
            duration: 0,
            breedUsed: breed.characteristics.name,
            startWeather: weatherSnapshot,
            safetyLevel: .safe
        )
        
        startTimer()
    }
    
    func pauseWalk() {
        walkState = .paused
        timer?.invalidate()
        pausedTime = walkDuration
    }
    
    func resumeWalk() {
        walkState = .walking
        startTime = Date().addingTimeInterval(-pausedTime)
        startTimer()
    }
    
    func stopWalk(endWeather: WeatherResponse? = nil) {
        walkState = .completed
        timer?.invalidate()
        
        guard var walk = currentWalk else { return }
        
        walk = WalkRecord(
            id: walk.id,
            date: walk.date,
            duration: walkDuration,
            breedUsed: walk.breedUsed,
            startWeather: walk.startWeather,
            endWeather: endWeather != nil ? WeatherSnapshot(from: endWeather!) : nil,
            warningsEncountered: warningsEncountered,
            safetyLevel: walk.safetyLevel
        )
        
        saveWalk(walk)
        
        // Update streak for walks longer than 1 minute
        if walkDuration > 60 {
            updateStreak()
        }
        
        resetWalk()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateWalkDuration()
        }
    }
    
    private func updateWalkDuration() {
        guard let startTime = startTime else { return }
        walkDuration = Date().timeIntervalSince(startTime) + pausedTime
    }
    
    private func resetWalk() {
        walkState = .notWalking
        walkDuration = 0
        startTime = nil
        pausedTime = 0
        currentWalk = nil
        warningsEncountered = []
        timer?.invalidate()
        timer = nil
    }
    
    func addWarning(_ warning: WarningType) {
        if !warningsEncountered.contains(warning) {
            warningsEncountered.append(warning)
        }
    }
    
    private func saveWalk(_ walk: WalkRecord) {
        walkHistory.insert(walk, at: 0)
        if walkHistory.count > 20 { // Keep only last 20 walks
            walkHistory = Array(walkHistory.prefix(20))
        }
        saveWalkHistory()
    }
    
    func saveWalkHistory() {
        if let encoded = try? JSONEncoder().encode(walkHistory) {
            UserDefaults.standard.set(encoded, forKey: "walkHistory")
        }
    }
    
    private func loadWalkHistory() {
        if let data = UserDefaults.standard.data(forKey: "walkHistory"),
           let decoded = try? JSONDecoder().decode([WalkRecord].self, from: data) {
            walkHistory = decoded
        }
    }
    
    func getWeeklyStats() -> (totalWalks: Int, totalDuration: TimeInterval, averageDuration: TimeInterval) {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let weeklyWalks = walkHistory.filter { $0.date >= oneWeekAgo }
        let totalWalks = weeklyWalks.count
        let totalDuration = weeklyWalks.reduce(0) { $0 + $1.duration }
        let averageDuration = totalWalks > 0 ? totalDuration / Double(totalWalks) : 0
        
        return (totalWalks, totalDuration, averageDuration)
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Calendar Helper Functions
    func getWeekDays() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysFromSunday = weekday - 1
        
        guard let weekStart = calendar.date(byAdding: .day, value: -daysFromSunday, to: today) else {
            return []
        }
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
        }
    }
    
    func hasWalkOnDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return walkHistory.contains { walk in
            calendar.isDate(walk.date, inSameDayAs: date)
        }
    }
} 