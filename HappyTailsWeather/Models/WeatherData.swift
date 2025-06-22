import Foundation

struct WeatherResponse: Codable {
    let coord: Coordinates
    let weather: [Weather]
    let main: MainWeatherData
    let wind: Wind?
    let clouds: Clouds?
    let sys: SystemData
    let name: String
    let visibility: Int?
    let dt: Int
    let timezone: Int?
    let id: Int
    let cod: Int
}

struct Coordinates: Codable {
    let lat: Double
    let lon: Double
}

struct Weather: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct MainWeatherData: Codable {
    let temp: Double
    let feels_like: Double
    let temp_min: Double
    let temp_max: Double
    let pressure: Int
    let humidity: Int
}

struct Wind: Codable {
    let speed: Double
    let deg: Int?
}

struct Clouds: Codable {
    let all: Int
}

struct SystemData: Codable {
    let country: String
    let sunrise: Int
    let sunset: Int
} 