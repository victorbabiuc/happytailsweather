import SwiftUI
import CoreLocation

struct HomeView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var weatherService: WeatherService
    @Binding var showingLocationPermissionAlert: Bool
    @Binding var selectedTab: Int
    @AppStorage("selectedBreed") private var selectedBreed: DogBreed = .labradorRetriever
    @State private var showingDetailedWeather = false
    @State private var isRefreshing = false
    
    private var safetyAssessment: SafetyAssessment? {
        guard let weatherData = weatherService.weatherData else { return nil }
        return SafetyAssessmentEngine.assess(weather: weatherData, breed: selectedBreed)
    }
    
    var body: some View {
        ZStack {
            // Background with safety-based tint
            safetyBackgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Section
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                // Hero Section with Temperature and Weather
                heroSection
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // Consolidated Warning Section (if warnings exist)
                if let assessment = safetyAssessment, !assessment.activeWarnings.isEmpty {
                    consolidatedWarningSection(assessment)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                }
                
                // Start Walk Button (Primary Action)
                startWalkButton
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                
                // Walk Recommendations Section
                if let assessment = safetyAssessment {
                    walkRecommendationsSection(assessment)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                }
                
                // Enhanced Weather Details Section
                enhancedDetailsSection
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                Spacer()
            }
        }
        .refreshable {
            await refreshWeather()
        }
        .alert("Location Access Required", isPresented: $showingLocationPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Happy Tails Weather needs your location to provide accurate weather information for your area.")
        }
        .sheet(isPresented: $showingDetailedWeather) {
            detailedWeatherSheet
        }
    }
    
    // MARK: - Background Color Based on Safety
    private var safetyBackgroundColor: Color {
        guard let assessment = safetyAssessment else { return Color(.systemBackground) }
        
        switch assessment.safetyLevel {
        case .safe:
            return Color.green.opacity(0.05)
        case .caution:
            return Color.orange.opacity(0.05)
        case .unsafe:
            return Color.red.opacity(0.05)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(locationService.city.isEmpty ? "Loading location..." : locationService.city)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                // Breed name removed to save space
            }
            Spacer()
            
            // Refresh button
            Button(action: {
                Task {
                    await refreshWeather()
                }
            }) {
                Image(systemName: isRefreshing ? "arrow.clockwise.circle.fill" : "arrow.clockwise.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
            }
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Temperature and Weather Icon
            HStack(spacing: 20) {
                // Large Temperature Display
                VStack(alignment: .leading, spacing: 4) {
                    if weatherService.hasWeatherData {
                        Text(weatherService.formattedTemperature(weatherService.currentTemperature))
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Feels like \(weatherService.formattedTemperature(weatherService.feelsLikeTemperature))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("--°F")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                        Text("Loading weather...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Weather Icon
                VStack(spacing: 8) {
                    if weatherService.hasWeatherData {
                        Image(systemName: weatherIcon)
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        Text(weatherService.weatherCondition ?? "Unknown")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    } else {
                        Image(systemName: "cloud")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Loading...")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .onTapGesture {
                showingDetailedWeather = true
            }
        }
    }
    
    // MARK: - Consolidated Warning Section
    private func consolidatedWarningSection(_ assessment: SafetyAssessment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Warning header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.headline)
                Text(assessment.recommendation)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            // Active warnings as badges
            HStack(spacing: 8) {
                ForEach(assessment.activeWarnings, id: \.self) { warning in
                    HStack(spacing: 4) {
                        Image(systemName: iconForWarning(warning))
                            .font(.caption)
                        Text(warning.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    // MARK: - Start Walk Button
    private var startWalkButton: some View {
        Button(action: {
            selectedTab = 1 // Navigate to Walk tab
        }) {
            HStack(spacing: 12) {
                Image(systemName: "figure.walk")
                    .font(.title2)
                Text("Start Walk")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .fill(Color.blue)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .scaleEffect(weatherService.isLoading || locationService.locationStatus == .requesting ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: weatherService.isLoading || locationService.locationStatus == .requesting)
        .disabled(weatherService.isLoading || locationService.locationStatus == .requesting)
    }
    
    // MARK: - Walk Recommendations Section
    private func walkRecommendationsSection(_ assessment: SafetyAssessment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundColor(.blue)
                    .font(.headline)
                Text("Walk Recommendations")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Duration
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                        .frame(width: 16)
                    Text("Duration: \(assessment.walkDuration.displayName)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                // Best Times (show at least 2 fully)
                VStack(alignment: .leading, spacing: 4) {
                    // Header with icon
                    HStack {
                        Image(systemName: "sunrise")
                            .foregroundColor(.orange)
                        Text("Best Times:")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    
                    // Stacked time ranges
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(assessment.bestTimeRecommendations.prefix(2), id: \.displayText) { timeRange in
                            Text(timeRange.displayText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Always show premium hint for now (no subscription system yet)
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("See hourly forecast →")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Color.blue.opacity(0.1))
        )
    }
    
    // MARK: - Enhanced Weather Details Section
    private var enhancedDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "thermometer.sun")
                    .foregroundColor(.blue)
                    .font(.headline)
                Text("Weather Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Button("More") {
                    showingDetailedWeather = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if weatherService.hasWeatherData {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    enhancedConditionRow(
                        icon: "thermometer",
                        title: "Humidity",
                        value: weatherService.formattedHumidity(weatherService.humidity),
                        color: .blue
                    )
                    enhancedConditionRow(
                        icon: "wind",
                        title: "Wind",
                        value: weatherService.formattedWindSpeed(weatherService.windSpeed),
                        color: .blue
                    )
                    enhancedConditionRow(
                        icon: "sun.max",
                        title: "UV Index",
                        value: "Moderate",
                        color: .orange
                    )
                    enhancedConditionRow(
                        icon: "thermometer.sun",
                        title: "Feels Like",
                        value: weatherService.formattedTemperature(weatherService.feelsLikeTemperature),
                        color: .red
                    )
                }
            } else {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text("Loading weather details...")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
    }
    
    // MARK: - Detailed Weather Sheet
    private var detailedWeatherSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let assessment = safetyAssessment {
                    // Walk Recommendations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Walk Recommendations")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                            Text("Duration: \(assessment.walkDuration.displayName)")
                                .font(.subheadline)
                            Spacer()
                        }
                        
                        if !assessment.bestTimeRecommendations.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Best Times:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                ForEach(assessment.bestTimeRecommendations, id: \.displayText) { timeRange in
                                    HStack {
                                        Image(systemName: "clock.badge.checkmark")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                        Text(timeRange.displayText)
                                            .font(.subheadline)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                
                // Full Weather Conditions
                VStack(alignment: .leading, spacing: 16) {
                    Text("Current Conditions")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        conditionRow(
                            icon: "thermometer",
                            title: "Temperature",
                            value: weatherService.formattedTemperature(weatherService.currentTemperature)
                        )
                        conditionRow(
                            icon: "thermometer.sun",
                            title: "Feels Like",
                            value: weatherService.formattedTemperature(weatherService.feelsLikeTemperature)
                        )
                        conditionRow(
                            icon: "humidity",
                            title: "Humidity",
                            value: weatherService.formattedHumidity(weatherService.humidity)
                        )
                        conditionRow(
                            icon: "wind",
                            title: "Wind Speed",
                            value: weatherService.formattedWindSpeed(weatherService.windSpeed)
                        )
                        conditionRow(
                            icon: "sun.max",
                            title: "UV Index",
                            value: "Moderate"
                        )
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                        .fill(Color(.systemGray6))
                )
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Weather Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingDetailedWeather = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private func enhancedConditionRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
    }
    
    private func compactConditionRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
    }
    
    private func conditionRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
    }
    
    private func safetyLevelBadge(_ level: SafetyLevel) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(safetyStatusColor(level))
                .frame(width: 8, height: 8)
            Text(level.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(safetyStatusColor(level))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(safetyStatusColor(level).opacity(0.2))
        .cornerRadius(8)
    }
    
    private func warningChip(_ warning: WarningType) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(.orange)
            Text(warning.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.2))
        .cornerRadius(6)
    }
    
    // MARK: - Helper Functions
    private func safetyStatusIcon(_ level: SafetyLevel) -> String {
        switch level {
        case .safe:
            return "checkmark.circle.fill"
        case .caution:
            return "exclamationmark.triangle.fill"
        case .unsafe:
            return "xmark.circle.fill"
        }
    }
    
    private func safetyStatusColor(_ level: SafetyLevel) -> Color {
        switch level {
        case .safe:
            return .green
        case .caution:
            return .orange
        case .unsafe:
            return .red
        }
    }
    
    private func iconForWarning(_ warning: WarningType) -> String {
        switch warning {
        case .heatstroke:
            return "thermometer.sun"
        case .dehydration:
            return "drop"
        case .pawBurn:
            return "flame"
        case .hypothermia:
            return "thermometer.snowflake"
        case .windChill:
            return "wind"
        }
    }
    
    private var weatherIcon: String {
        guard let weatherData = weatherService.weatherData else { return "cloud" }
        
        let condition = weatherData.weather.first?.main.lowercased() ?? ""
        switch condition {
        case "clear":
            return "sun.max.fill"
        case "clouds":
            return "cloud.fill"
        case "rain", "drizzle":
            return "cloud.rain.fill"
        case "snow":
            return "cloud.snow.fill"
        case "thunderstorm":
            return "cloud.bolt.rain.fill"
        case "mist", "fog":
            return "cloud.fog.fill"
        default:
            return "cloud.fill"
        }
    }
    
    private func fullBestTimesText(_ assessment: SafetyAssessment) -> String {
        let times = assessment.bestTimeRecommendations.prefix(2).map { $0.displayText }
        return times.joined(separator: ", ")
    }
    
    private func refreshWeather() async {
        isRefreshing = true
        if let location = locationService.currentLocation {
            await weatherService.fetchWeather(for: location)
        }
        isRefreshing = false
    }
}

// MARK: - Extensions
extension SafetyLevel {
    var displayName: String {
        switch self {
        case .safe:
            return "Safe"
        case .caution:
            return "Caution"
        case .unsafe:
            return "Unsafe"
        }
    }
} 