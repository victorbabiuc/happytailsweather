import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var city: String = ""
    @Published var locationStatus: LocationStatus = .idle
    @Published var errorMessage: String = ""
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100
    }
    
    func requestLocationPermission() {
        print("📍 LocationService: Requesting location permission")
        
        DispatchQueue.main.async {
            self.locationStatus = .requesting
            self.errorMessage = ""
        }
        
        // Check current authorization status
        let status = locationManager.authorizationStatus
        print("📍 LocationService: Current authorization status: \(status.rawValue)")
        
        switch status {
        case .notDetermined:
            print("📍 LocationService: Authorization not determined - requesting permission")
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 LocationService: Already authorized - starting location updates")
            startLocationUpdates()
        case .denied, .restricted:
            print("📍 LocationService: Authorization denied/restricted")
            DispatchQueue.main.async {
                self.locationStatus = .failed
                self.errorMessage = "Location access denied. Please enable in Settings."
            }
        @unknown default:
            print("📍 LocationService: Unknown authorization status")
            DispatchQueue.main.async {
                self.locationStatus = .failed
                self.errorMessage = "Unknown authorization status."
            }
        }
    }
    
    private func startLocationUpdates() {
        print("📍 LocationService: Starting location updates")
        locationManager.startUpdatingLocation()
    }
    
    private func stopLocationUpdates() {
        print("📍 LocationService: Stopping location updates")
        locationManager.stopUpdatingLocation()
    }
    
    private func geocodeLocation(_ location: CLLocation) {
        print("📍 LocationService: Geocoding location")
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error = error {
                print("📍 LocationService: Geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self?.city = placemark.locality ?? "Unknown"
                    print("📍 LocationService: City resolved: \(placemark.locality ?? "Unknown")")
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 LocationService: Authorization status changed to: \(status.rawValue)")
        
        DispatchQueue.main.async { [weak self] in
            self?.authorizationStatus = status
        }
        
        // Handle all authorization scenarios in the delegate method
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 LocationService: Authorization granted - starting location updates")
            startLocationUpdates()
        case .denied, .restricted:
            print("📍 LocationService: Authorization denied/restricted")
            DispatchQueue.main.async { [weak self] in
                self?.locationStatus = .failed
                self?.errorMessage = "Location access denied. Please enable in Settings."
            }
        case .notDetermined:
            print("📍 LocationService: Authorization not determined - waiting for user decision")
            // User will be prompted for permission, wait for their decision
            break
        @unknown default:
            print("📍 LocationService: Unknown authorization status")
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { 
            print("📍 LocationService: No location in update")
            return 
        }
        
        print("📍 LocationService: Location updated - lat: \(location.coordinate.latitude), lon: \(location.coordinate.longitude)")
        
        DispatchQueue.main.async { [weak self] in
            self?.currentLocation = location
            self?.locationStatus = .success
            self?.errorMessage = ""
        }
        
        geocodeLocation(location)
        stopLocationUpdates()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 LocationService: Location failed with error: \(error.localizedDescription)")
        
        // Check if the error is due to location services being disabled
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                // Location services disabled system-wide
                DispatchQueue.main.async { [weak self] in
                    self?.locationStatus = .failed
                    self?.errorMessage = "Location services are disabled. Please enable in Settings."
                }
            case .locationUnknown:
                // Location temporarily unavailable
                DispatchQueue.main.async { [weak self] in
                    self?.locationStatus = .failed
                    self?.errorMessage = "Unable to determine location. Please try again."
                }
            default:
                DispatchQueue.main.async { [weak self] in
                    self?.locationStatus = .failed
                    self?.errorMessage = "Failed to get location: \(error.localizedDescription)"
                }
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.locationStatus = .failed
                self?.errorMessage = "Failed to get location: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Location Status Enum
enum LocationStatus {
    case idle
    case requesting
    case success
    case failed
} 