import Foundation
import CoreLocation
import Combine

enum LocationStatus {
    case idle
    case requesting
    case success
    case failed
}

class LocationService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var locationStatus: LocationStatus = .idle
    @Published var currentLocation: CLLocation?
    @Published var currentCity: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1000 // Update every 1km
    }
    
    // MARK: - Public Methods
    func requestLocationPermission() {
        DispatchQueue.main.async {
            self.locationStatus = .requesting
            self.errorMessage = nil
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            switch self.locationManager.authorizationStatus {
            case .notDetermined:
                self.locationManager.requestWhenInUseAuthorization()
            case .denied, .restricted:
                DispatchQueue.main.async {
                    self.locationStatus = .failed
                    self.errorMessage = "Location access is required to provide weather information for your area."
                }
            case .authorizedWhenInUse, .authorizedAlways:
                self.getCurrentLocation()
            @unknown default:
                DispatchQueue.main.async {
                    self.locationStatus = .failed
                    self.errorMessage = "Unknown authorization status."
                }
            }
        }
    }
    
    func getCurrentLocation() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard CLLocationManager.locationServicesEnabled() else {
                DispatchQueue.main.async {
                    self.locationStatus = .failed
                    self.errorMessage = "Location services are disabled. Please enable in Settings."
                }
                return
            }
            
            DispatchQueue.main.async {
                self.locationStatus = .requesting
                self.errorMessage = nil
            }
            self.locationManager.startUpdatingLocation()
        }
    }
    
    func stopLocationUpdates() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.locationManager.stopUpdatingLocation()
        }
        DispatchQueue.main.async {
            self.locationStatus = .idle
        }
    }
    
    func geocodeLocation(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Unable to determine city name: \(error.localizedDescription)"
                    return
                }
                
                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? placemark.administrativeArea ?? "Unknown Location"
                    self?.currentCity = city
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.currentLocation = location
            self?.locationStatus = .success
            self?.errorMessage = nil
            
            // Geocode the location to get city name
            self?.geocodeLocation(location)
            
            // Stop updates after getting a good location
            self?.stopLocationUpdates()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.locationStatus = .failed
            
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self?.errorMessage = "Location access denied. Please enable in Settings."
                case .locationUnknown:
                    self?.errorMessage = "Unable to determine location. Please try again."
                case .network:
                    self?.errorMessage = "Network error. Please check your connection."
                default:
                    self?.errorMessage = "Location error: \(error.localizedDescription)"
                }
            } else {
                self?.errorMessage = "Location error: \(error.localizedDescription)"
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async { [weak self] in
            self?.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self?.getCurrentLocation()
            case .denied, .restricted:
                self?.locationStatus = .failed
                self?.errorMessage = "Location access is required to provide weather information for your area."
            case .notDetermined:
                self?.locationStatus = .idle
            @unknown default:
                self?.locationStatus = .failed
                self?.errorMessage = "Unknown authorization status."
            }
        }
    }
} 