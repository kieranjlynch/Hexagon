import Foundation
import CoreLocation
import EventKit
import Photos

class PermissionManager: NSObject, CLLocationManagerDelegate {
    static let shared = PermissionManager()
    
    private let locationManager = CLLocationManager()
    private let eventStore = EKEventStore()
    
    private override init() {
        super.init()
        locationManager.delegate = self
    }
    
    // MARK: - Location Permissions

    func requestLocationPermission(completion: @escaping (Bool) -> Void) {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            completion(false)
        case .authorizedWhenInUse, .authorizedAlways:
            completion(true)
        @unknown default:
            completion(false)
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            NotificationCenter.default.post(name: .locationPermissionChanged, object: nil, userInfo: ["granted": true])
        case .denied, .restricted:
            NotificationCenter.default.post(name: .locationPermissionChanged, object: nil, userInfo: ["granted": false])
        default:
            break
        }
    }
    
    // MARK: - Calendar Permissions
    
    func requestCalendarPermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }
    
    // MARK: - Photo Library Permissions
    
    func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    
    // MARK: - Check Permission Status
    
    func checkLocationPermission() -> Bool {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }
    
    func checkCalendarPermission() -> Bool {
        if #available(iOS 17.0, *) {
            return EKEventStore.authorizationStatus(for: .event) == .fullAccess
        } else {
            return EKEventStore.authorizationStatus(for: .event) == .authorized
        }
    }
    
    func checkPhotoLibraryPermission() -> Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
}

extension Notification.Name {
    static let locationPermissionChanged = Notification.Name("locationPermissionChanged")
}
