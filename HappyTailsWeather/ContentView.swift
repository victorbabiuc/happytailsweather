//
//  ContentView.swift
//  HappyTailsWeather
//
//  Created by Vik on 6/18/25.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationService = LocationService()
    @StateObject private var weatherService = WeatherService()
    @State private var showingSplash = true
    
    var body: some View {
        ZStack {
            if showingSplash {
                SplashScreenView(
                    weatherService: weatherService,
                    locationService: locationService,
                    onSplashComplete: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showingSplash = false
                        }
                    }
                )
            } else {
                MainTabView(
                    locationService: locationService,
                    weatherService: weatherService
                )
            }
        }
        .onAppear {
            // Start loading weather data in background during splash
            if let location = locationService.currentLocation {
                Task {
                    await weatherService.fetchWeather(for: location)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
