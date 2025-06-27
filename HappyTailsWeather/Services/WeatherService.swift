import Foundation
import Combine
import CoreLocation

@MainActor
class WeatherService: ObservableObject {
    // MARK: - Published Properties
    @Published var weatherData: WeatherResponse?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    
    // MARK: - Private Properties
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    func fetchWeather(for location: CLLocation) async {
        await fetchWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
    
    func fetchWeather(for city: String) async {
        guard let url = buildWeatherURL(city: city) else {
            await handleError("Invalid city name: \(city)")
            return
        }
        
        await performWeatherRequest(url: url)
    }
    
    func refreshWeather() async {
        guard let weatherData = weatherData else {
            await handleError("No weather data available to refresh")
            return
        }
        
        // Refresh using the last known location
        await fetchWeather(latitude: weatherData.coord.lat, longitude: weatherData.coord.lon)
    }
    
    // MARK: - Private Methods
    private func fetchWeather(latitude: Double, longitude: Double) async {
        guard let url = buildWeatherURL(latitude: latitude, longitude: longitude) else {
            await handleError("Invalid coordinates")
            return
        }
        
        await performWeatherRequest(url: url)
    }
    
    private func buildWeatherURL(latitude: Double, longitude: Double) -> URL? {
        var components = URLComponents(string: Constants.API.openWeatherMapBaseURL + Constants.API.currentWeatherEndpoint)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "appid", value: Constants.openWeatherMapAPIKey),
            URLQueryItem(name: "units", value: Constants.API.units)
        ]
        return components?.url
    }
    
    private func buildWeatherURL(city: String) -> URL? {
        var components = URLComponents(string: Constants.API.openWeatherMapBaseURL + Constants.API.currentWeatherEndpoint)
        components?.queryItems = [
            URLQueryItem(name: "q", value: city),
            URLQueryItem(name: "appid", value: Constants.openWeatherMapAPIKey),
            URLQueryItem(name: "units", value: Constants.API.units)
        ]
        return components?.url
    }
    
    private func performWeatherRequest(url: URL) async {
        print("🌤️ WeatherService: Starting weather request for URL: \(url)")
        isLoading = true
        errorMessage = nil
        
        do {
            let (data, response) = try await session.data(from: url)
            
            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ WeatherService: Invalid response type")
                await handleError("Invalid response from server")
                return
            }
            
            print("🌤️ WeatherService: HTTP Status Code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                print("❌ WeatherService: API Error - Status: \(httpResponse.statusCode)")
                await handleAPIError(statusCode: httpResponse.statusCode, data: data)
                return
            }
            
            // Decode weather data
            let decoder = JSONDecoder()
            let weatherResponse = try decoder.decode(WeatherResponse.self, from: data)
            
            print("✅ WeatherService: Successfully decoded weather data for \(weatherResponse.name)")
            
            // Update on main actor
            weatherData = weatherResponse
            lastUpdated = Date()
            isLoading = false
            
        } catch let decodingError as DecodingError {
            print("❌ WeatherService: Decoding error: \(decodingError)")
            await handleDecodingError(decodingError)
        } catch {
            print("❌ WeatherService: Network error: \(error.localizedDescription)")
            await handleError("Network error: \(error.localizedDescription)")
        }
    }
    
    private func handleAPIError(statusCode: Int, data: Data) async {
        var errorMessage = "API Error (Status: \(statusCode))"
        
        // Try to extract error message from API response
        if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = errorResponse["message"] as? String {
            errorMessage = "API Error: \(message)"
        }
        
        await handleError(errorMessage)
    }
    
    private func handleDecodingError(_ error: DecodingError) async {
        let errorMessage: String
        
        switch error {
        case .keyNotFound(let key, _):
            errorMessage = "Missing data field: \(key.stringValue)"
        case .typeMismatch(_, let context):
            errorMessage = "Data type mismatch: \(context.debugDescription)"
        case .valueNotFound(_, let context):
            errorMessage = "Missing value: \(context.debugDescription)"
        case .dataCorrupted(let context):
            errorMessage = "Data corrupted: \(context.debugDescription)"
        @unknown default:
            errorMessage = "Unknown decoding error"
        }
        
        await handleError(errorMessage)
    }
    
    private func handleError(_ message: String) async {
        errorMessage = message
        isLoading = false
    }
}

// MARK: - Weather Service Extensions
extension WeatherService {
    /// Get current temperature in Fahrenheit
    var currentTemperature: Double {
        weatherData?.main.temp ?? 0.0
    }
    
    /// Get feels like temperature in Fahrenheit
    var feelsLikeTemperature: Double {
        weatherData?.main.feels_like ?? 0.0
    }
    
    /// Get humidity percentage
    var humidity: Int {
        weatherData?.main.humidity ?? 0
    }
    
    /// Get wind speed in mph
    var windSpeed: Double {
        weatherData?.wind?.speed ?? 0.0
    }
    
    /// Get weather description
    var weatherDescription: String? {
        weatherData?.weather.first?.description.capitalized
    }
    
    /// Get weather condition (e.g., "Clear", "Rain")
    var weatherCondition: String? {
        weatherData?.weather.first?.main
    }
    
    /// Check if weather data is available
    var hasWeatherData: Bool {
        weatherData != nil
    }
    
    /// Get formatted temperature string
    func formattedTemperature(_ temperature: Double) -> String {
        return "\(Int(round(temperature)))°F"
    }
    
    /// Get formatted humidity string
    func formattedHumidity(_ humidity: Int) -> String {
        return "\(humidity)%"
    }
    
    /// Get formatted wind speed string
    func formattedWindSpeed(_ windSpeed: Double) -> String {
        return "\(Int(round(windSpeed))) mph"
    }
} 