import SwiftUI

struct SplashScreenView: View {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @State private var isAnimating = false
    @State private var showSplash = true
    @State private var messageOpacity: Double = 0
    @State private var tailRotation: Double = 0
    @State private var currentMessageIndex = 0
    
    let weatherService: WeatherService
    let locationService: LocationService
    let onSplashComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Icon/Logo Area
                VStack(spacing: 20) {
                    // Tail wagging animation
                    Image(systemName: "dog.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(tailRotation))
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true),
                            value: tailRotation
                        )
                    
                    // Welcome message (only on first launch)
                    if !hasLaunchedBefore {
                        Text("Welcome to Happy Tails!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .opacity(messageOpacity)
                            .scaleEffect(messageOpacity)
                            .animation(.easeInOut(duration: 0.8), value: messageOpacity)
                    }
                }
                
                // Dynamic message
                VStack(spacing: 12) {
                    Text(dynamicMessage)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .opacity(messageOpacity)
                        .scaleEffect(messageOpacity)
                        .animation(.easeInOut(duration: 0.8).delay(0.3), value: messageOpacity)
                        .id(currentMessageIndex) // Force refresh when message changes
                    
                    Text("🐕")
                        .font(.system(size: 40))
                        .opacity(messageOpacity)
                        .animation(.easeInOut(duration: 0.8).delay(0.5), value: messageOpacity)
                }
                
                Spacer()
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startAnimations()
            scheduleDismissal()
            startMessageUpdates()
        }
    }
    
    // MARK: - Dynamic Message Logic
    private var dynamicMessage: String {
        // If we have weather data, use weather-based messages
        if weatherService.hasWeatherData {
            return weatherBasedMessage
        } else {
            // Otherwise use time-based messages
            return timeBasedMessage
        }
    }
    
    private var weatherBasedMessage: String {
        guard let weatherData = weatherService.weatherData else {
            return timeBasedMessage
        }
        
        let temperature = weatherData.main.temp
        let weatherCondition = weatherData.weather.first?.main.lowercased() ?? ""
        
        // Temperature-based messages
        if temperature > 85 {
            return "Hot paws alert! Let's time this right 🥵"
        } else if temperature < 32 {
            return "Brrr! Time to check if your pup needs a coat 🧥"
        }
        
        // Weather condition-based messages
        switch weatherCondition {
        case "clear":
            return "Perfect day for tails wagging! ☀️"
        case "clouds":
            return "Clouds won't stop the fun! Let's walk safe ☁️"
        case "rain", "drizzle":
            return "Wet paws ahead! Let's keep them safe 🌧️"
        case "snow":
            return "Snow zoomies? Let's check if it's safe! ❄️"
        case "thunderstorm":
            return "Stormy weather! Let's wait for better conditions ⚡"
        case "mist", "fog":
            return "Foggy adventure? Let's keep it safe! 🌫️"
        default:
            return "Let's check the weather for your walk! 🌤️"
        }
    }
    
    private var timeBasedMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<10:
            return "Ready for walkies? Let's check if it's safe! 🌅"
        case 10..<17:
            return "Time for an adventure? Let's make it safe! ☀️"
        case 17..<21:
            return "Evening stroll? We've got you covered! 🌆"
        default:
            return "Late night potty break? Let's keep it safe! 🌙"
        }
    }
    
    // MARK: - Animation Methods
    private func startAnimations() {
        // Start tail wagging
        tailRotation = 15
        
        // Fade in messages
        withAnimation(.easeInOut(duration: 0.8)) {
            messageOpacity = 1.0
        }
    }
    
    private func startMessageUpdates() {
        // Update message every 1.5 seconds to show weather data when it loads
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            currentMessageIndex += 1
            if !showSplash {
                timer.invalidate()
            }
        }
    }
    
    private func scheduleDismissal() {
        // Dismiss after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showSplash = false
            }
            
            // Mark as launched and call completion
            hasLaunchedBefore = true
            onSplashComplete()
        }
    }
}

#Preview {
    SplashScreenView(
        weatherService: WeatherService(),
        locationService: LocationService(),
        onSplashComplete: {}
    )
} 