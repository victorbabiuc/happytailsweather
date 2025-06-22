import Foundation

enum DogBreed: String, CaseIterable, Hashable {
    case labradorRetriever = "labradorRetriever"
    case goldenRetriever = "goldenRetriever"
    case bulldog = "bulldog"
    case husky = "husky"
    case germanShepherd = "germanShepherd"
    case chihuahua = "chihuahua"
    case poodle = "poodle"
    case beagle = "beagle"
    case mixed = "mixed"
    
    var characteristics: BreedCharacteristics {
        switch self {
        case .labradorRetriever:
            return BreedCharacteristics(
                name: "Labrador Retriever",
                safeTemperatureRange: 60.0...80.0,
                cautionTemperatureRange: 81.0...90.0,
                maxHumidity: 70.0,
                maxWindSpeed: 20.0,
                coatType: .short,
                sizeCategory: .large,
                heatSensitivity: .moderate
            )
        case .goldenRetriever:
            return BreedCharacteristics(
                name: "Golden Retriever",
                safeTemperatureRange: 60.0...80.0,
                cautionTemperatureRange: 81.0...90.0,
                maxHumidity: 70.0,
                maxWindSpeed: 20.0,
                coatType: .long,
                sizeCategory: .large,
                heatSensitivity: .moderate
            )
        case .bulldog:
            return BreedCharacteristics(
                name: "Bulldog",
                safeTemperatureRange: 60.0...75.0,
                cautionTemperatureRange: 76.0...85.0,
                maxHumidity: 60.0,
                maxWindSpeed: 15.0,
                coatType: .short,
                sizeCategory: .medium,
                heatSensitivity: .high
            )
        case .husky:
            return BreedCharacteristics(
                name: "Husky",
                safeTemperatureRange: 20.0...75.0,
                cautionTemperatureRange: 76.0...85.0,
                maxHumidity: 50.0,
                maxWindSpeed: 25.0,
                coatType: .double,
                sizeCategory: .large,
                heatSensitivity: .high
            )
        case .germanShepherd:
            return BreedCharacteristics(
                name: "German Shepherd",
                safeTemperatureRange: 55.0...80.0,
                cautionTemperatureRange: 81.0...90.0,
                maxHumidity: 65.0,
                maxWindSpeed: 20.0,
                coatType: .double,
                sizeCategory: .large,
                heatSensitivity: .moderate
            )
        case .chihuahua:
            return BreedCharacteristics(
                name: "Chihuahua",
                safeTemperatureRange: 50.0...80.0,
                cautionTemperatureRange: 81.0...85.0,
                maxHumidity: 70.0,
                maxWindSpeed: 15.0,
                coatType: .short,
                sizeCategory: .small,
                heatSensitivity: .moderate
            )
        case .poodle:
            return BreedCharacteristics(
                name: "Poodle",
                safeTemperatureRange: 60.0...80.0,
                cautionTemperatureRange: 81.0...90.0,
                maxHumidity: 70.0,
                maxWindSpeed: 20.0,
                coatType: .long,
                sizeCategory: .medium,
                heatSensitivity: .moderate
            )
        case .beagle:
            return BreedCharacteristics(
                name: "Beagle",
                safeTemperatureRange: 60.0...80.0,
                cautionTemperatureRange: 81.0...90.0,
                maxHumidity: 70.0,
                maxWindSpeed: 20.0,
                coatType: .short,
                sizeCategory: .medium,
                heatSensitivity: .moderate
            )
        case .mixed:
            return BreedCharacteristics(
                name: "Mixed Breed",
                safeTemperatureRange: 65.0...78.0,
                cautionTemperatureRange: 55.0...64.0,
                maxHumidity: 65.0,
                maxWindSpeed: 18.0,
                coatType: .mixed,
                sizeCategory: .varies,
                heatSensitivity: .moderate
            )
        }
    }
    
    func safetyAssessment(for temperature: Double, humidity: Double, windSpeed: Double) -> SafetyLevel {
        let tempInRange = characteristics.safeTemperatureRange.contains(temperature)
        let humiditySafe = humidity <= characteristics.maxHumidity
        let windSafe = windSpeed <= characteristics.maxWindSpeed
        
        if tempInRange && humiditySafe && windSafe {
            return .safe
        } else if characteristics.cautionTemperatureRange.contains(temperature) {
            return .caution
        } else if self == .mixed {
            // For mixed breeds, check both high and low caution ranges
            let lowCautionRange = 55.0...64.0
            let highCautionRange = 79.0...85.0
            if lowCautionRange.contains(temperature) || highCautionRange.contains(temperature) {
                return .caution
            } else {
                return .unsafe
            }
        } else {
            return .unsafe
        }
    }
    
    func walkRecommendation(for conditions: WeatherConditions) -> String {
        let safety = safetyAssessment(for: conditions.temperature, humidity: conditions.humidity, windSpeed: conditions.windSpeed)
        
        switch safety {
        case .safe:
            return "Perfect for walks!"
        case .caution:
            return "Use caution - check breed-specific recommendations"
        case .unsafe:
            if conditions.temperature > characteristics.safeTemperatureRange.upperBound {
                return "Too hot for walks! Risk of paw burns and overheating."
            } else {
                return "Too cold for most dogs! Keep walks very short."
            }
        }
    }
}

struct BreedCharacteristics {
    let name: String
    let safeTemperatureRange: ClosedRange<Double>
    let cautionTemperatureRange: ClosedRange<Double>
    let maxHumidity: Double
    let maxWindSpeed: Double
    let coatType: CoatType
    let sizeCategory: SizeCategory
    let heatSensitivity: HeatSensitivity
    
    func safetyAssessment(for temperature: Double, humidity: Double, windSpeed: Double) -> SafetyLevel {
        // Check temperature first
        if safeTemperatureRange.contains(temperature) {
            // Check other conditions
            if humidity > maxHumidity {
                return .caution
            }
            if windSpeed > maxWindSpeed {
                return .caution
            }
            return .safe
        } else if cautionTemperatureRange.contains(temperature) {
            return .caution
        } else {
            return .unsafe
        }
    }
    
    func walkRecommendation(for conditions: WeatherConditions) -> String {
        let safetyLevel = safetyAssessment(
            for: conditions.temperature,
            humidity: conditions.humidity,
            windSpeed: conditions.windSpeed
        )
        
        switch safetyLevel {
        case .safe:
            return Constants.SafetyMessages.safe
        case .caution:
            return Constants.SafetyMessages.caution
        case .unsafe:
            return Constants.SafetyMessages.unsafe
        }
    }
}

enum CoatType {
    case short
    case medium
    case long
    case double
    case mixed
}

enum SizeCategory {
    case small
    case medium
    case large
    case extraLarge
    case varies
}

enum HeatSensitivity {
    case low
    case moderate
    case high
    case extreme
}

enum SafetyLevel: Codable {
    case safe
    case caution
    case unsafe
}

struct WeatherConditions {
    let temperature: Double
    let humidity: Double
    let windSpeed: Double
}

// MARK: - Display Name Extensions
extension CoatType {
    var displayName: String {
        switch self {
        case .short: return "Short"
        case .medium: return "Medium"
        case .long: return "Long"
        case .double: return "Double"
        case .mixed: return "Mixed"
        }
    }
}

extension SizeCategory {
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "XL"
        case .varies: return "Varies"
        }
    }
}

extension HeatSensitivity {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .extreme: return "Extreme"
        }
    }
} 