import Foundation

enum WarningType: CaseIterable, Codable {
    case heatstroke
    case dehydration
    case pawBurn
    case hypothermia
    case windChill
    
    var displayName: String {
        switch self {
        case .heatstroke:
            return "Heatstroke Risk"
        case .dehydration:
            return "Dehydration Risk"
        case .pawBurn:
            return "Paw Burn Risk"
        case .hypothermia:
            return "Hypothermia Risk"
        case .windChill:
            return "Wind Chill Risk"
        }
    }
}

struct SafetyAssessment {
    let safetyLevel: SafetyLevel
    let activeWarnings: [WarningType]
    let walkDuration: WalkDuration
    let recommendation: String
    let bestTimeRecommendations: [TimeRange]
    
    init(safetyLevel: SafetyLevel, activeWarnings: [WarningType], walkDuration: WalkDuration, recommendation: String, bestTimeRecommendations: [TimeRange] = []) {
        self.safetyLevel = safetyLevel
        self.activeWarnings = activeWarnings
        self.walkDuration = walkDuration
        self.recommendation = recommendation
        self.bestTimeRecommendations = bestTimeRecommendations
    }
}

enum WalkDuration: CaseIterable {
    case short
    case moderate
    case recommended
    case extended
    
    var displayName: String {
        switch self {
        case .short:
            return "5-15 minutes"
        case .moderate:
            return "20-30 minutes"
        case .recommended:
            return "30-45 minutes"
        case .extended:
            return "45+ minutes"
        }
    }
    
    var maxMinutes: Int {
        switch self {
        case .short:
            return 15
        case .moderate:
            return 30
        case .recommended:
            return 45
        case .extended:
            return 120
        }
    }
}

struct TimeRange {
    let startTime: String
    let endTime: String
    let period: String
    
    var displayText: String {
        return "\(startTime) - \(endTime) (\(period))"
    }
}

struct SafetyAssessmentEngine {
    
    static func assess(weather: WeatherResponse, breed: DogBreed) -> SafetyAssessment {
        let temperature = weather.main.temp
        let humidity = Double(weather.main.humidity)
        let windSpeed = weather.wind?.speed ?? 0.0
        
        let safetyLevel = breed.characteristics.safetyAssessment(
            for: temperature,
            humidity: humidity,
            windSpeed: windSpeed
        )
        
        let warnings = generateWarnings(
            temperature: temperature,
            humidity: humidity,
            windSpeed: windSpeed,
            breed: breed
        )
        
        let walkDuration = recommendWalkDuration(safetyLevel: safetyLevel, breed: breed)
        
        let recommendation = generateRecommendationMessage(
            assessment: SafetyAssessment(
                safetyLevel: safetyLevel,
                activeWarnings: warnings,
                walkDuration: walkDuration,
                recommendation: ""
            ),
            breed: breed
        )
        
        let bestTimes = generateBestTimeRecommendations(
            temperature: temperature,
            humidity: humidity,
            windSpeed: windSpeed,
            breed: breed
        )
        
        return SafetyAssessment(
            safetyLevel: safetyLevel,
            activeWarnings: warnings,
            walkDuration: walkDuration,
            recommendation: recommendation,
            bestTimeRecommendations: bestTimes
        )
    }
    
    static func generateWarnings(temperature: Double, humidity: Double, windSpeed: Double, breed: DogBreed) -> [WarningType] {
        var warnings: [WarningType] = []
        
        // Heat-related warnings
        if temperature > 85.0 {
            warnings.append(.heatstroke)
            warnings.append(.pawBurn)
        } else if temperature > 75.0 && humidity > 70.0 {
            warnings.append(.dehydration)
        }
        
        // Cold-related warnings
        if temperature < 32.0 {
            warnings.append(.hypothermia)
        }
        
        if temperature < 45.0 && windSpeed > 15.0 {
            warnings.append(.windChill)
        }
        
        // Breed-specific adjustments
        switch breed.characteristics.heatSensitivity {
        case .high, .extreme:
            if temperature > 75.0 {
                warnings.append(.heatstroke)
            }
        default:
            break
        }
        
        return warnings
    }
    
    static func recommendWalkDuration(safetyLevel: SafetyLevel, breed: DogBreed) -> WalkDuration {
        switch safetyLevel {
        case .safe:
            return .recommended
        case .caution:
            return .moderate
        case .unsafe:
            return .short
        }
    }
    
    static func generateRecommendationMessage(assessment: SafetyAssessment, breed: DogBreed) -> String {
        switch assessment.safetyLevel {
        case .safe:
            return Constants.SafetyMessages.safe
        case .caution:
            var message = Constants.SafetyMessages.caution
            if !assessment.activeWarnings.isEmpty {
                message += " Active warnings: \(assessment.activeWarnings.map { $0.displayName }.joined(separator: ", "))."
            }
            return message
        case .unsafe:
            if assessment.activeWarnings.contains(.heatstroke) || assessment.activeWarnings.contains(.pawBurn) {
                return "Too hot for walks! Risk of paw burns and overheating."
            } else if assessment.activeWarnings.contains(.hypothermia) {
                return "Too cold for most dogs! Keep walks very short."
            } else {
                return Constants.SafetyMessages.unsafe
            }
        }
    }
    
    static func generateBestTimeRecommendations(temperature: Double, humidity: Double, windSpeed: Double, breed: DogBreed) -> [TimeRange] {
        var recommendations: [TimeRange] = []
        
        // Morning recommendations (cooler temperatures)
        if temperature > 75.0 || humidity > 70.0 {
            recommendations.append(TimeRange(
                startTime: "6:00 AM",
                endTime: "8:00 AM",
                period: "Early Morning"
            ))
        }
        
        // Evening recommendations
        if temperature > 80.0 {
            recommendations.append(TimeRange(
                startTime: "7:00 PM",
                endTime: "9:00 PM",
                period: "Evening"
            ))
        }
        
        // Mid-day for cold weather
        if temperature < 45.0 {
            recommendations.append(TimeRange(
                startTime: "12:00 PM",
                endTime: "2:00 PM",
                period: "Mid-day"
            ))
        }
        
        return recommendations
    }
} 