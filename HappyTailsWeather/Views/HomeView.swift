import SwiftUI
import CoreLocation

struct HomeView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var weatherService: WeatherService
    @Binding var showingLocationPermissionAlert: Bool
    @Binding var selectedTab: Int
    @AppStorage("selectedBreed") private var selectedBreed: DogBreed = .labradorRetriever
    @AppStorage("isPremium") private var isPremium: Bool = false
    
    private var safetyAssessment: SafetyAssessment? {
        guard let weatherData = weatherService.weatherData else { return nil }
        return SafetyAssessmentEngine.assess(weather: weatherData, breed: selectedBreed)
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    weatherStatusCard
                    safetyAssessmentCard
                    todaysBestTimesSection
                    currentConditionsCard
                    startWalkButton
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
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
    }
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(locationService.currentCity ?? "Loading location...")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(selectedBreed.characteristics.name)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                Spacer()
                if selectedBreed == .labradorRetriever {
                    Text("Default")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
            }
            if locationService.authorizationStatus == .authorizedWhenInUse {
                Text("Using your current location")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    private var weatherStatusCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    if weatherService.hasWeatherData {
                        Text(weatherService.formattedTemperature(weatherService.currentTemperature))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Feels like \(weatherService.formattedTemperature(weatherService.feelsLikeTemperature))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("--°F")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                        Text("Loading weather...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    if weatherService.hasWeatherData {
                        Text(weatherService.weatherCondition ?? "Unknown")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text(weatherService.weatherDescription ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("--")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text("Loading...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Color(.systemGray6))
        )
    }
    private var safetyAssessmentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Safety Assessment")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if let assessment = safetyAssessment {
                    safetyLevelIndicator(assessment.safetyLevel)
                }
            }
            
            if let assessment = safetyAssessment {
                VStack(alignment: .leading, spacing: 12) {
                    // Safety Status Message
                    HStack {
                        Image(systemName: safetyStatusIcon(assessment.safetyLevel))
                            .foregroundColor(safetyStatusColor(assessment.safetyLevel))
                            .font(.title2)
                        Text(assessment.recommendation)
                            .font(.headline)
                            .foregroundColor(safetyStatusColor(assessment.safetyLevel))
                        Spacer()
                    }
                    
                    // Active Warnings
                    if !assessment.activeWarnings.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Active Warnings")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(assessment.activeWarnings, id: \.self) { warning in
                                    warningChip(warning)
                                }
                            }
                        }
                    }
                    
                    // Walk Recommendations
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Walk Recommendations")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                                .font(.subheadline)
                            Text("Duration: \(assessment.walkDuration.displayName)")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        if !assessment.bestTimeRecommendations.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Best Times:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                ForEach(assessment.bestTimeRecommendations, id: \.displayText) { timeRange in
                                    Text("• \(timeRange.displayText)")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
            } else {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                        .font(.title2)
                    Text("Loading safety assessment...")
                        .font(.headline)
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Color(.systemGray6))
        )
    }
    private var todaysBestTimesSection: some View {
        TodaysBestTimesView(
            isPremium: isPremium,
            selectedBreed: selectedBreed,
            weatherData: weatherService.weatherData,
            onUpgrade: {
                // Navigate to Profile tab for upgrade
                selectedTab = 2
            }
        )
    }
    private var currentConditionsCard: some View {
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
                    value: weatherService.hasWeatherData ? weatherService.formattedTemperature(weatherService.currentTemperature) : "Loading..."
                )
                conditionRow(
                    icon: "humidity",
                    title: "Humidity",
                    value: weatherService.hasWeatherData ? weatherService.formattedHumidity(weatherService.humidity) : "Loading..."
                )
                conditionRow(
                    icon: "wind",
                    title: "Wind Speed",
                    value: weatherService.hasWeatherData ? weatherService.formattedWindSpeed(weatherService.windSpeed) : "Loading..."
                )
                conditionRow(
                    icon: "sun.max",
                    title: "UV Index",
                    value: "Moderate"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Color(.systemGray6))
        )
    }
    private var startWalkButton: some View {
        Button(action: {
            selectedTab = 1 // Navigate to Walk tab
        }) {
            HStack {
                Image(systemName: "figure.walk")
                    .font(.title2)
                Text("Start Walk")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .fill(Color(red: 0, green: 122/255, blue: 255/255))
            )
        }
        .disabled(weatherService.isLoading || locationService.locationStatus == .requesting)
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
    private func safetyLevelIndicator(_ level: SafetyLevel) -> some View {
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
        .background(safetyStatusColor(level).opacity(0.1))
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
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
    }
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