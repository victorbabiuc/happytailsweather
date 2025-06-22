//
//  Constants.swift
//  HappyTailsWeather
//
//  Created by Vik on 2025-06-21.
//

import Foundation

struct Constants {
    // IMPORTANT: To make this app work, you must get your own API key from OpenWeatherMap
    // and place it in a new file named "Secrets.swift".
    //
    // 1. Create a new file in your project: File -> New -> File -> Swift File
    // 2. Name it "Secrets.swift"
    // 3. Add the following content to Secrets.swift:
    //
    //    struct Secrets {
    //        static let openWeatherMapAPIKey = "YOUR_NEW_API_KEY_HERE"
    //    }
    //
    // This `Secrets.swift` file is already listed in your .gitignore and will not be committed.
    
    // The app will now securely access the key from the untracked Secrets.swift file.
    static let openWeatherMapAPIKey = Secrets.openWeatherMapAPIKey
    
    struct API {
        static let openWeatherMapBaseURL = "https://api.openweathermap.org/data/2.5"
        static let currentWeatherEndpoint = "/weather"
        static let units = "imperial" // Fahrenheit
    }
    
    struct Weather {
        static let temperatureThresholds = TemperatureThresholds()
        static let humidityThreshold = 70.0
        static let windSpeedThreshold = 20.0
        static let uvIndexThreshold = 7.0
    }
    
    struct WeatherThresholds {
        static let safeMinTempF: Double = 60.0
        static let safeMaxTempF: Double = 80.0
        static let cautionMinTempF: Double = 81.0
        static let cautionMaxTempF: Double = 90.0
        static let unsafeLowTempF: Double = 59.9
        static let unsafeHighTempF: Double = 90.1
        static let highHumidity: Double = 70.0 // percent
        static let strongWind: Double = 20.0 // mph
    }
    
    struct UI {
        static let primaryBlue = "#007AFF"
        static let cornerRadius: CGFloat = 12
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 8
        static let animationDuration: Double = 0.3
    }
    
    struct UserDefaults {
        static let selectedBreed = "selectedBreed"
        static let isPremium = "isPremium"
        static let notificationsEnabled = "notificationsEnabled"
        static let temperatureUnit = "temperatureUnit"
        static let dogName = "dogName"
        static let onboardingStatus = "onboardingStatus"
        static let lastLocationUpdate = "lastLocationUpdate"
    }
    
    struct SafetyMessages {
        static let safe = "Perfect for walks!"
        static let caution = "Exercise caution during walks"
        static let unsafe = "Avoid outdoor activities"
        static let highHumidity = "High humidity: Dogs may overheat more easily."
        static let strongWind = "Strong wind: Use caution, especially for small breeds."
        static func breedSpecific(_ breed: String) -> String {
            return "Check recommendations for your breed: \(breed)."
        }
    }
    
    struct App {
        static let name = "Happy Tails Weather"
    }
    
    struct Premium {
        static let upgradeTitle = "Unlock Premium Features"
        static let upgradeSubtitle = "Get personalized walking recommendations and advanced safety insights"
        static let upgradeButtonText = "Upgrade to Premium"
        static let premiumBadge = "🌟 Premium"
        static let bestTimesTitle = "Today's Best Times"
        static let bestTimesSubtitle = "Optimal walking windows for your dog"
        
        static let upgradePrompts = [
            "Get personalized walking times based on weather and your dog's breed",
            "Access detailed hourly weather analysis and safety predictions",
            "Receive priority safety alerts and extended breed recommendations",
            "Unlock advanced features for the ultimate dog walking experience"
        ]
        
        static let premiumBenefits = [
            "Today's Best Times - Optimal walking windows",
            "Hourly weather breakdown and predictions",
            "Extended breed-specific safety tips",
            "Priority safety alerts and notifications",
            "Advanced warning predictions",
            "Enhanced walk tracking and analytics"
        ]
    }
    
    struct BestTimes {
        static let maxTimeWindows = 4
        static let minWindowDuration: TimeInterval = 3600 // 1 hour
        static let preferredStartTime = 6 // 6 AM
        static let preferredEndTime = 20 // 8 PM
        static let temperatureWeight = 0.4
        static let humidityWeight = 0.2
        static let windWeight = 0.2
        static let uvWeight = 0.2
    }
}

struct TemperatureThresholds {
    let safeRange = 60.0...80.0
    let cautionRange = 50.0...90.0
    let unsafeRange = 0.0...100.0
} 