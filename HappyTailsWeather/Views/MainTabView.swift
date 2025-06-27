import SwiftUI

struct MainTabView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var weatherService: WeatherService
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
            
            WalkView(locationService: locationService, weatherService: weatherService)
                .tabItem {
                    Image(systemName: "figure.walk")
                    Text("Walk")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .onAppear {
            print("📍 MainTabView: App appeared - requesting location permission")
            locationService.requestLocationPermission()
        }
        .onChange(of: locationService.currentLocation) { oldValue, newValue in
            if let location = newValue {
                print("📍 MainTabView: Location updated - lat: \(location.coordinate.latitude), lon: \(location.coordinate.longitude)")
                print("🌤️ MainTabView: Fetching weather for new location...")
                Task {
                    await weatherService.fetchWeather(for: location)
                }
            }
        }
        .onChange(of: locationService.locationStatus) { oldValue, newValue in
            print("📍 MainTabView: Location status changed to: \(newValue)")
            if newValue == .failed {
                showingLocationPermissionAlert = true
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
            Text(locationService.errorMessage.isEmpty ? "Location access is required to provide weather information for your area." : locationService.errorMessage)
        }
    }
}

#Preview {
    MainTabView(
        locationService: LocationService(),
        weatherService: WeatherService()
    )
} 