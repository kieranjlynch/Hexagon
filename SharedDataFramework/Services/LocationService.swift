import Foundation
import MapKit

struct SearchCompletions: Identifiable {
    let id = UUID()
    let title: String
    let subTitle: String
    var url: URL?
}

@Observable
class LocationService: NSObject, MKLocalSearchCompleterDelegate, CLLocationManagerDelegate {
    static let shared = LocationService(completer: .init())
    
    let completer: MKLocalSearchCompleter
    private var locationManager: CLLocationManager
    private var monitoredReminders: [UUID: CLCircularRegion] = [:]
    
    var completions = [SearchCompletions]()
    
    init(completer: MKLocalSearchCompleter) {
        self.completer = completer
        self.locationManager = CLLocationManager()
        super.init()
        self.completer.delegate = self
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
    }
    
    func update(queryFragment: String) {
        completer.resultTypes = .pointOfInterest
        completer.queryFragment = queryFragment
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results.map { completion in
            let mapItem = completion.value(forKey: "_mapItem") as? MKMapItem
            return .init(
                title: completion.title,
                subTitle: completion.subtitle,
                url: mapItem?.url
            )
        }
    }
    
    func search(with query: String, coordinate: CLLocationCoordinate2D? = nil) async throws -> [SearchResult] {
        let mapKitRequest = MKLocalSearch.Request()
        mapKitRequest.naturalLanguageQuery = query
        mapKitRequest.resultTypes = .pointOfInterest
        if let coordinate {
            mapKitRequest.region = .init(.init(origin: .init(coordinate), size: .init(width: 1, height: 1)))
        }
        let search = MKLocalSearch(request: mapKitRequest)
        
        let response = try await search.start()
        
        return response.mapItems.compactMap { mapItem in
            guard let location = mapItem.placemark.location?.coordinate else { return nil }
            return .init(location: location)
        }
    }
    
    func startMonitoringLocation(for reminder: Reminder) {
        guard let location = reminder.location else { return }
        
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            radius: reminder.radius,
            identifier: reminder.identifier?.uuidString ?? UUID().uuidString
        )
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        monitoredReminders[reminder.identifier!] = region
        locationManager.startMonitoring(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        guard let reminderId = UUID(uuidString: circularRegion.identifier) else { return }

        let reminderService = ReminderService()
        do {
            if let reminder = try reminderService.getReminderById(id: reminderId) {
                sendNotification(for: reminder)
            }
        } catch {
            print("Failed to fetch reminder for region: \(error)")
        }
    }
    
    private func sendNotification(for reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = reminder.title ?? "You have a reminder"
        
        let request = UNNotificationRequest(
            identifier: reminder.identifier?.uuidString ?? UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to add notification request: \(error)")
            }
        }
    }
}
