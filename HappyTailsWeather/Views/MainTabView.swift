import SwiftUI

struct MainTabView: View {
    @StateObject private var locationService = LocationService()
    @StateObject private var weatherService = WeatherService()
    @State private var showingLocationPermissionAlert = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                locationService: locationService,
                weatherService: weatherService,
                showingLocationPermissionAlert: $showingLocationPermissionAlert,
                selectedTab: $selectedTab
            )
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            .onAppear {
                setupLocationAndWeather()
            }
            
            WalkView(
                locationService: locationService,
                weatherService: weatherService
            )
            .tabItem {
                Image(systemName: "figure.walk")
                Text("Walk")
            }
            .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
                .tag(2)
        }
    }
    
    private func setupLocationAndWeather() {
        locationService.requestLocationPermission()
        
        Task {
            // Add timeout to prevent infinite loop
            let timeoutSeconds: UInt64 = 10 // 10 second timeout
            let startTime = DispatchTime.now()
            
            while locationService.locationStatus != .success {
                // Check if we've exceeded timeout
                let elapsed = DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds
                let elapsedSeconds = elapsed / 1_000_000_000
                
                if elapsedSeconds >= timeoutSeconds {
                    print("Location setup timeout - showing alert")
                    showingLocationPermissionAlert = true
                    return
                }
                
                // Check for failure
                if locationService.locationStatus == .failed {
                    print("Location setup failed - showing alert")
                    showingLocationPermissionAlert = true
                    return
                }
                
                // Wait before checking again
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            // Success - fetch weather
            if let location = locationService.currentLocation {
                await weatherService.fetchWeather(for: location)
            }
        }
    }
}

#Preview {
    MainTabView()
} 