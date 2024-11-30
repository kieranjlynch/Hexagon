//
//  LocationMonitoringManager.swift
//  Hexagon
//
//  Created by Kieran Lynch on 03/11/2024.
//

import CoreLocation
import UserNotifications


protocol LocationMonitoringFacade: Sendable {
    func startMonitoring(location: LocationModel, reminderIdentifier: String, reminderTitle: String) async
    func stopMonitoring(reminderIdentifier: String) async
}

@MainActor
class LocationMonitoringManager: NSObject, CLLocationManagerDelegate, LocationMonitoringFacade {
    static let shared = LocationMonitoringManager()
    
    private let manager = CLLocationManager()
    
    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    nonisolated func startMonitoring(location: LocationModel, reminderIdentifier: String, reminderTitle: String) async {
        await MainActor.run {
            let region = CLCircularRegion(
                center: CLLocationCoordinate2D(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                ),
                radius: 100,
                identifier: reminderIdentifier
            )
            region.notifyOnEntry = true
            
            Task {
                do {
                    let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                    guard granted else { return }
                    
                    let content = UNMutableNotificationContent()
                    content.title = "Nearby Location"
                    content.body = "You are near \(location.name): \(reminderTitle)"
                    content.sound = .default
                    
                    let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
                    let request = UNNotificationRequest(
                        identifier: reminderIdentifier,
                        content: content,
                        trigger: trigger
                    )
                    
                    try await UNUserNotificationCenter.current().add(request)
                    manager.startMonitoring(for: region)
                } catch {
                    print("Failed to set up monitoring: \(error.localizedDescription)")
                }
            }
        }
    }
    
    nonisolated func stopMonitoring(reminderIdentifier: String) async {
        await MainActor.run {
            for region in manager.monitoredRegions {
                if region.identifier == reminderIdentifier {
                    manager.stopMonitoring(for: region)
                }
            }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
        }
    }
}

enum LocationError: Error {
    case unknownAuthorizationStatus
    case monitoringFailed
    case notificationPermissionDenied
}
