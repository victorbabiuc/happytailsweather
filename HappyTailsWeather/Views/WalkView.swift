import SwiftUI

struct WalkView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var weatherService: WeatherService
    @StateObject private var walkManager = WalkManager()
    @AppStorage("selectedBreed") private var selectedBreed: DogBreed = .labradorRetriever
    @State private var showingWalkSummary = false
    
    private var safetyAssessment: SafetyAssessment? {
        guard let weatherData = weatherService.weatherData else { return nil }
        return SafetyAssessmentEngine.assess(weather: weatherData, breed: selectedBreed)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Safety Card
                    currentSafetyCard
                    
                    // Walk Controls Section
                    walkControlsSection
                    
                    // Real-Time Monitoring (during walk)
                    if walkManager.walkState == .walking || walkManager.walkState == .paused {
                        realTimeMonitoringSection
                    }
                    
                    // Walk History Section
                    walkHistorySection
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Walk Tracking")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingWalkSummary) {
                walkSummaryView
            }
            .onReceive(weatherService.$weatherData) { _ in
                if let assessment = safetyAssessment,
                   walkManager.walkState == .walking {
                    // Update warnings during walk
                    for warning in assessment.activeWarnings {
                        walkManager.addWarning(warning)
                    }
                }
            }
        }
    }
    
    // MARK: - Current Safety Card
    private var currentSafetyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Safety")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(selectedBreed.characteristics.name)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                Spacer()
                if let assessment = safetyAssessment {
                    safetyLevelIndicator(assessment.safetyLevel)
                }
            }
            
            if let assessment = safetyAssessment {
                VStack(alignment: .leading, spacing: 12) {
                    // Safety Status
                    HStack {
                        Image(systemName: safetyStatusIcon(assessment.safetyLevel))
                            .foregroundColor(safetyStatusColor(assessment.safetyLevel))
                            .font(.title2)
                        Text(assessment.recommendation)
                            .font(.subheadline)
                            .foregroundColor(safetyStatusColor(assessment.safetyLevel))
                        Spacer()
                    }
                    
                    // Active Warnings
                    if !assessment.activeWarnings.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Warnings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 6) {
                                ForEach(assessment.activeWarnings, id: \.self) { warning in
                                    warningChip(warning)
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
                        .font(.subheadline)
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
    
    // MARK: - Walk Controls Section
    private var walkControlsSection: some View {
        VStack(spacing: 16) {
            switch walkManager.walkState {
            case .notWalking:
                startWalkButton
            case .walking:
                walkingControls
            case .paused:
                pausedControls
            case .completed:
                completedState
            }
        }
    }
    
    private var startWalkButton: some View {
        Button(action: {
            guard let weatherData = weatherService.weatherData else { return }
            walkManager.startWalk(breed: selectedBreed, startWeather: weatherData)
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
                    .fill(Color.blue)
            )
        }
        .disabled(weatherService.isLoading || locationService.locationStatus == .requesting)
    }
    
    private var walkingControls: some View {
        VStack(spacing: 16) {
            // Timer Display
            VStack(spacing: 8) {
                Text("Walk Duration")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(walkManager.formatDuration(walkManager.walkDuration))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }
            
            // Control Buttons
            HStack(spacing: 16) {
                Button(action: {
                    walkManager.pauseWalk()
                }) {
                    HStack {
                        Image(systemName: "pause.fill")
                        Text("Pause")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .fill(Color.orange)
                    )
                }
                
                Button(action: {
                    guard let weatherData = weatherService.weatherData else { return }
                    walkManager.stopWalk(endWeather: weatherData)
                    showingWalkSummary = true
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .fill(Color.red)
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Color(.systemGray6))
        )
    }
    
    private var pausedControls: some View {
        VStack(spacing: 16) {
            // Timer Display
            VStack(spacing: 8) {
                Text("Walk Paused")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(walkManager.formatDuration(walkManager.walkDuration))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }
            
            // Control Buttons
            HStack(spacing: 16) {
                Button(action: {
                    walkManager.resumeWalk()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Resume")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .fill(Color.green)
                    )
                }
                
                Button(action: {
                    guard let weatherData = weatherService.weatherData else { return }
                    walkManager.stopWalk(endWeather: weatherData)
                    showingWalkSummary = true
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .fill(Color.red)
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Color(.systemGray6))
        )
    }
    
    private var completedState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("Walk Completed!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Button("Start New Walk") {
                walkManager.walkState = .notWalking
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Real-Time Monitoring Section
    private var realTimeMonitoringSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Live Monitoring")
                .font(.headline)
                .fontWeight(.semibold)
            
            if safetyAssessment != nil {
                VStack(alignment: .leading, spacing: 12) {
                    // Current Conditions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Conditions")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            conditionRow(
                                icon: "thermometer",
                                title: "Temperature",
                                value: weatherService.formattedTemperature(weatherService.currentTemperature)
                            )
                            conditionRow(
                                icon: "humidity",
                                title: "Humidity",
                                value: weatherService.formattedHumidity(weatherService.humidity)
                            )
                        }
                    }
                    
                    // Active Warnings During Walk
                    if !walkManager.warningsEncountered.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Warnings During Walk")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 6) {
                                ForEach(walkManager.warningsEncountered, id: \.self) { warning in
                                    warningChip(warning)
                                }
                            }
                        }
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
    
    // MARK: - Walk History Section
    private var walkHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Walk History")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if !walkManager.walkHistory.isEmpty {
                    Button("Clear All") {
                        walkManager.walkHistory.removeAll()
                        walkManager.saveWalkHistory()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            
            if walkManager.walkHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No walks recorded yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(walkManager.walkHistory.prefix(5)) { walk in
                        walkHistoryRow(walk)
                    }
                }
            }
            
            // Weekly Statistics
            let stats = walkManager.getWeeklyStats()
            if stats.totalWalks > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This Week")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        statItem("Walks", "\(stats.totalWalks)")
                        statItem("Total Time", walkManager.formatDuration(stats.totalDuration))
                        statItem("Avg Duration", walkManager.formatDuration(stats.averageDuration))
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Walk Summary View
    private var walkSummaryView: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let lastWalk = walkManager.walkHistory.first {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Walk Completed!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 8) {
                            Text("Duration: \(walkManager.formatDuration(lastWalk.duration))")
                                .font(.headline)
                            Text("Breed: \(lastWalk.breedUsed)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if !lastWalk.warningsEncountered.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Warnings Encountered:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                ForEach(lastWalk.warningsEncountered, id: \.self) { warning in
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                        Text(warning.displayName)
                                    }
                                    .font(.caption)
                                }
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                Button("Done") {
                    showingWalkSummary = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Walk Summary")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Helper Views
    private func walkHistoryRow(_ walk: WalkRecord) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(walkManager.formatDuration(walk.duration))
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(walk.breedUsed)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(walk.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(walk.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !walk.warningsEncountered.isEmpty {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private func statItem(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func conditionRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
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
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(4)
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

#Preview {
    WalkView(
        locationService: LocationService(),
        weatherService: WeatherService()
    )
} 