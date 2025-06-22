import Foundation

struct OptimalWalkTime: Identifiable {
    let id = UUID()
    let timeRange: String
    let safetyLevel: SafetyLevel
    let temperature: String
    let reasoning: String
    let uvIndex: String
    let recommendation: String
    let score: Double // 0.0 to 1.0, higher is better
    
    init(
        timeRange: String,
        safetyLevel: SafetyLevel,
        temperature: String,
        reasoning: String,
        uvIndex: String,
        recommendation: String,
        score: Double
    ) {
        self.timeRange = timeRange
        self.safetyLevel = safetyLevel
        self.temperature = temperature
        self.reasoning = reasoning
        self.uvIndex = uvIndex
        self.recommendation = recommendation
        self.score = score
    }
}

class BestTimesCalculator {
    static func calculateBestTimes(
        for breed: DogBreed,
        currentWeather: WeatherResponse?,
        hourlyForecast: [WeatherResponse]? = nil
    ) -> [OptimalWalkTime] {
        var optimalTimes: [OptimalWalkTime] = []
        
        // Generate time windows throughout the day
        let timeWindows = generateTimeWindows()
        
        for window in timeWindows {
            let optimalTime = calculateOptimalTime(
                for: breed,
                timeWindow: window,
                currentWeather: currentWeather,
                hourlyForecast: hourlyForecast
            )
            optimalTimes.append(optimalTime)
        }
        
        // Sort by score (highest first) and return top results
        return optimalTimes
            .sorted { $0.score > $1.score }
            .prefix(Constants.BestTimes.maxTimeWindows)
            .map { $0 }
    }
    
    private static func generateTimeWindows() -> [(start: Int, end: Int)] {
        let windows = [
            (6, 9),   // Early morning
            (9, 12),  // Late morning
            (15, 18), // Late afternoon
            (18, 21)  // Evening
        ]
        return windows
    }
    
    private static func calculateOptimalTime(
        for breed: DogBreed,
        timeWindow: (start: Int, end: Int),
        currentWeather: WeatherResponse?,
        hourlyForecast: [WeatherResponse]? = nil
    ) -> OptimalWalkTime {
        let startTime = timeWindow.start
        let endTime = timeWindow.end
        
        // Use current weather as fallback if no hourly forecast
        let weather = hourlyForecast?.first { response in
            let hour = Calendar.current.component(.hour, from: Date())
            return hour >= startTime && hour < endTime
        } ?? currentWeather
        
        guard let weather = weather else {
            return createDefaultOptimalTime(timeWindow: timeWindow, breed: breed)
        }
        
        let temperature = weather.main.temp
        let humidity = Double(weather.main.humidity)
        let windSpeed = weather.wind?.speed ?? 0.0
        
        // Calculate safety score based on breed characteristics
        let safetyScore = calculateSafetyScore(
            temperature: temperature,
            humidity: humidity,
            windSpeed: windSpeed,
            breed: breed
        )
        
        let safetyLevel = determineSafetyLevel(score: safetyScore)
        let timeRange = formatTimeRange(start: startTime, end: endTime)
        let temperatureRange = formatTemperatureRange(temperature: temperature)
        let reasoning = generateReasoning(
            temperature: temperature,
            humidity: humidity,
            windSpeed: windSpeed,
            breed: breed,
            timeWindow: timeWindow
        )
        let uvIndex = estimateUVIndex(timeWindow: timeWindow)
        let recommendation = generateRecommendation(
            safetyLevel: safetyLevel,
            breed: breed,
            timeWindow: timeWindow
        )
        
        return OptimalWalkTime(
            timeRange: timeRange,
            safetyLevel: safetyLevel,
            temperature: temperatureRange,
            reasoning: reasoning,
            uvIndex: uvIndex,
            recommendation: recommendation,
            score: safetyScore
        )
    }
    
    private static func calculateSafetyScore(
        temperature: Double,
        humidity: Double,
        windSpeed: Double,
        breed: DogBreed
    ) -> Double {
        let characteristics = breed.characteristics
        
        // Temperature score (0.0 to 1.0)
        let tempScore: Double
        if characteristics.safeTemperatureRange.contains(temperature) {
            tempScore = 1.0
        } else if characteristics.cautionTemperatureRange.contains(temperature) {
            tempScore = 0.6
        } else {
            tempScore = 0.2
        }
        
        // Humidity score
        let humidityScore = humidity <= characteristics.maxHumidity ? 1.0 : 0.5
        
        // Wind score
        let windScore = windSpeed <= characteristics.maxWindSpeed ? 1.0 : 0.5
        
        // Weighted average
        let weightedScore = (tempScore * Constants.BestTimes.temperatureWeight) +
                           (humidityScore * Constants.BestTimes.humidityWeight) +
                           (windScore * Constants.BestTimes.windWeight)
        
        return min(max(weightedScore, 0.0), 1.0)
    }
    
    private static func determineSafetyLevel(score: Double) -> SafetyLevel {
        switch score {
        case 0.8...1.0:
            return .safe
        case 0.5..<0.8:
            return .caution
        default:
            return .unsafe
        }
    }
    
    private static func formatTimeRange(start: Int, end: Int) -> String {
        let startTime = formatHour(start)
        let endTime = formatHour(end)
        return "\(startTime) - \(endTime)"
    }
    
    private static func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        let date = calendar.date(from: components) ?? now
        let hourDate = calendar.date(byAdding: .hour, value: hour, to: date) ?? now
        
        return formatter.string(from: hourDate)
    }
    
    private static func formatTemperatureRange(temperature: Double) -> String {
        let temp = Int(round(temperature))
        return "\(temp)°F"
    }
    
    private static func generateReasoning(
        temperature: Double,
        humidity: Double,
        windSpeed: Double,
        breed: DogBreed,
        timeWindow: (start: Int, end: Int)
    ) -> String {
        let breedName = breed.characteristics.name
        let temp = Int(round(temperature))
        
        if temperature >= 70 && temperature <= 80 {
            return "Perfect \(temp)°F conditions for \(breedName)"
        } else if temperature >= 60 && temperature < 70 {
            return "Good \(temp)°F weather for \(breedName) walks"
        } else if temperature >= 50 && temperature < 60 {
            return "Cool \(temp)°F - suitable for \(breedName) with proper gear"
        } else if temperature > 80 {
            return "Warm \(temp)°F - keep walks short for \(breedName)"
        } else {
            return "Cold \(temp)°F - limit outdoor time for \(breedName)"
        }
    }
    
    private static func estimateUVIndex(timeWindow: (start: Int, end: Int)) -> String {
        let startHour = timeWindow.start
        let endHour = timeWindow.end
        
        if startHour >= 6 && endHour <= 10 {
            return "Low UV"
        } else if startHour >= 10 && endHour <= 16 {
            return "Moderate UV"
        } else {
            return "Low UV"
        }
    }
    
    private static func generateRecommendation(
        safetyLevel: SafetyLevel,
        breed: DogBreed,
        timeWindow: (start: Int, end: Int)
    ) -> String {
        let breedName = breed.characteristics.name
        
        switch safetyLevel {
        case .safe:
            return "Ideal for longer walks with \(breedName)"
        case .caution:
            return "Moderate walks recommended for \(breedName)"
        case .unsafe:
            return "Short walks only for \(breedName)"
        }
    }
    
    private static func createDefaultOptimalTime(
        timeWindow: (start: Int, end: Int),
        breed: DogBreed
    ) -> OptimalWalkTime {
        let timeRange = formatTimeRange(start: timeWindow.start, end: timeWindow.end)
        let breedName = breed.characteristics.name
        
        return OptimalWalkTime(
            timeRange: timeRange,
            safetyLevel: .caution,
            temperature: "70°F",
            reasoning: "Typical conditions for \(breedName)",
            uvIndex: "Low UV",
            recommendation: "Standard walking time for \(breedName)",
            score: 0.7
        )
    }
} 