import SwiftUI

struct TodaysBestTimesView: View {
    let isPremium: Bool
    let selectedBreed: DogBreed
    let weatherData: WeatherResponse?
    let onUpgrade: () -> Void
    
    @State private var optimalTimes: [OptimalWalkTime] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with premium badge
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(Constants.Premium.bestTimesTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if isPremium {
                    PremiumBadge()
                }
                
                Spacer()
            }
            
            if isPremium {
                premiumContent
            } else {
                freeUserContent
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .onAppear {
            if isPremium {
                calculateBestTimes()
            }
        }
    }
    
    private var premiumContent: some View {
        VStack(spacing: 12) {
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Calculating best times...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if optimalTimes.isEmpty {
                Text("Unable to calculate optimal times at the moment")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(optimalTimes) { optimalTime in
                        OptimalTimeCard(optimalTime: optimalTime)
                    }
                }
            }
        }
    }
    
    private var freeUserContent: some View {
        VStack(spacing: 16) {
            // Preview of what premium users get
            VStack(alignment: .leading, spacing: 8) {
                Text("Get personalized walking times based on:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    FeatureRow(icon: "thermometer", text: "Hourly temperature forecasts")
                    FeatureRow(icon: "humidity", text: "Humidity and wind conditions")
                    FeatureRow(icon: "sun.max", text: "UV index predictions")
                    FeatureRow(icon: "pawprint", text: "Breed-specific recommendations")
                }
            }
            
            // Sample optimal time (locked)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Sample: 7:00 AM - 9:00 AM")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                
                Text("Perfect conditions for \(selectedBreed.characteristics.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Upgrade prompt
            UpgradePrompt(
                title: "Unlock Today's Best Times",
                subtitle: "Get 3-4 optimal walking windows throughout the day, personalized for your \(selectedBreed.characteristics.name)",
                onUpgrade: onUpgrade
            )
        }
    }
    
    private func calculateBestTimes() {
        isLoading = true
        
        // Simulate calculation delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            optimalTimes = BestTimesCalculator.calculateBestTimes(
                for: selectedBreed,
                currentWeather: weatherData
            )
            isLoading = false
        }
    }
}

struct OptimalTimeCard: View {
    let optimalTime: OptimalWalkTime
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(optimalTime.timeRange)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                SafetyLevelBadge(level: optimalTime.safetyLevel)
            }
            
            HStack {
                Image(systemName: "thermometer")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text(optimalTime.temperature)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "sun.max")
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Text(optimalTime.uvIndex)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(optimalTime.reasoning)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Text(optimalTime.recommendation)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(safetyLevelColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var safetyLevelColor: Color {
        switch optimalTime.safetyLevel {
        case .safe:
            return .green
        case .caution:
            return .orange
        case .unsafe:
            return .red
        }
    }
}

struct SafetyLevelBadge: View {
    let level: SafetyLevel
    
    var body: some View {
        Text(level.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor)
            )
    }
    
    private var backgroundColor: Color {
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

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TodaysBestTimesView(
            isPremium: true,
            selectedBreed: DogBreed.allCases[0],
            weatherData: nil,
            onUpgrade: {}
        )
        
        TodaysBestTimesView(
            isPremium: false,
            selectedBreed: DogBreed.allCases[0],
            weatherData: nil,
            onUpgrade: {}
        )
    }
    .padding()
} 