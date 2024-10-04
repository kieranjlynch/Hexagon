//
//  LocationService.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import Foundation
import CoreLocation
import MapKit
import UserNotifications
import Combine
import CoreData

@MainActor
public class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate, MKLocalSearchCompleterDelegate {
    private let locationManager = CLLocationManager()
    private var monitoredReminders: [UUID: CLCircularRegion] = [:]
    
    @Published public var currentLocation: CLLocationCoordinate2D? = nil
    @Published public var searchCompletions: [SearchCompletion] = []
    @Published public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let completer = MKLocalSearchCompleter()
    
    override public init() {
        super.init()
        locationManager.delegate = self
        authorizationStatus = locationManager.authorizationStatus
        completer.delegate = self
    }
    
    public struct SearchCompletion: Identifiable {
        public let id = UUID()
        public let title: String
        public let subTitle: String
        public var url: URL?
    }
    
    public func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    public func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            Task { @MainActor in
                self.currentLocation = location.coordinate
                self.locationManager.stopUpdatingLocation()
            }
        }
    }
    
    nonisolated public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        guard let reminderId = UUID(uuidString: circularRegion.identifier) else { return }
        
        Task { @MainActor in
            self.sendNotification(for: reminderId)
        }
    }
    
    private func sendNotification(for reminderId: UUID) {
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = "You have entered the location for a reminder"
        
        let request = UNNotificationRequest(identifier: reminderId.uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
    
    public func update(queryFragment: String) {
        completer.resultTypes = .pointOfInterest
        completer.queryFragment = queryFragment
    }
    
    nonisolated public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            searchCompletions = completer.results.map { completion in
                let mapItem = completion.value(forKey: "_mapItem") as? MKMapItem
                return SearchCompletion(
                    title: completion.title,
                    subTitle: completion.subtitle,
                    url: mapItem?.url
                )
            }
        }
    }
    
    public func search(with query: String, coordinate: CLLocationCoordinate2D? = nil) async throws -> [SearchResult] {
        let mapKitRequest = MKLocalSearch.Request()
        mapKitRequest.naturalLanguageQuery = query
        mapKitRequest.resultTypes = .pointOfInterest
        if let coordinate = coordinate {
            mapKitRequest.region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        }
        let search = MKLocalSearch(request: mapKitRequest)
        
        let response = try await search.start()
        
        return response.mapItems.compactMap { mapItem in
            guard let location = mapItem.placemark.location?.coordinate else { return nil }
            return SearchResult(location: location)
        }
    }
    
    public func configureLocation(for reminder: Reminder, location: CLLocationCoordinate2D, radius: Double) async throws {
        let context = reminder.managedObjectContext!
        try await context.perform {
            let locationEntity = Location(context: context)
            locationEntity.latitude = location.latitude
            locationEntity.longitude = location.longitude
            locationEntity.name = "Reminder Location"
            reminder.location = locationEntity
            reminder.radius = radius
            try context.save()
        }
        startMonitoringLocation(for: reminder)
    }
    
    public func startMonitoringLocation(for reminder: Reminder) {
        guard let location = reminder.location else { return }
        
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            radius: reminder.radius,
            identifier: reminder.reminderID?.uuidString ?? UUID().uuidString
        )
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        if let identifier = reminder.reminderID {
            monitoredReminders[identifier] = region
        }
        locationManager.startMonitoring(for: region)
    }
    
    public func fetchLocations() async throws -> [Location] {
        let context = PersistenceController.shared.persistentContainer.viewContext
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        return try await context.perform {
            try context.fetch(request)
        }
    }

    public func saveLocation(name: String, latitude: Double, longitude: Double) async throws -> Location {
        let context = PersistenceController.shared.persistentContainer.viewContext
        return try await context.perform {
            let newLocation = Location(context: context)
            newLocation.name = name
            newLocation.latitude = latitude
            newLocation.longitude = longitude
            try context.save()
            return newLocation
        }
    }
}

public struct SearchResult: Identifiable, Hashable {
    public let id = UUID()
    public let location: CLLocationCoordinate2D
    
    public init(location: CLLocationCoordinate2D) {
        self.location = location
    }
    
    public static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
