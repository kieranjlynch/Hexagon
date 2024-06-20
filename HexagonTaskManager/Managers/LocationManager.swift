import Foundation
import CoreLocation

@Observable
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    var location: CLLocation? = nil
    
    private let locationManager = CLLocationManager()
    
    func startCurrentLocationUpdates() async throws {
        for try await locationUpdate in CLLocationUpdate.liveUpdates() {
            guard let location = locationUpdate.location else { return }
            
            self.location = location
        }
    }
}
