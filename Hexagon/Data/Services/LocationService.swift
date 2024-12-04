//
//  LocationService.swift
//  Hexagon
//
//  Created by Kieran Lynch on 02/11/2024.
//

import Foundation
import CoreData
import CoreLocation

public protocol LocationServiceFacade: BaseProvider where T == LocationModel {
    func saveLocation(_ name: String, coordinate: CLLocationCoordinate2D) async throws
    func deleteLocation(_ model: LocationModel) async throws
}

@MainActor
public class LocationService: LocationServiceFacade, LocationManaging {
    public static let shared = LocationService(persistenceController: PersistenceController.shared)
    private let persistentContainer: NSPersistentContainer
    
    public init(persistenceController: PersistenceController) {
        self.persistentContainer = persistenceController.persistentContainer
    }
    
    public func saveLocation(_ name: String, coordinate: CLLocationCoordinate2D) async throws {
        let context = persistentContainer.newBackgroundContext()
        try await context.perform {
            let location = Location(context: context)
            location.locationID = UUID()
            location.name = name
            location.latitude = coordinate.latitude
            location.longitude = coordinate.longitude as NSNumber
            try context.save()
        }
    }
    
    public func fetchLocations() async throws -> [LocationModel] {
        let context = persistentContainer.viewContext
        return try await context.perform {
            let request = Location.fetchRequest()
            let locations = try context.fetch(request)
            return locations.map { location in
                LocationModel(
                    id: location.locationID ?? UUID(),
                    name: location.name ?? "",
                    coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude?.doubleValue ?? 0.0
                    )
                )
            }
        }
    }
    
    public func deleteLocation(_ model: LocationModel) async throws {
        let context = persistentContainer.newBackgroundContext()
        try await context.perform {
            let request = Location.fetchRequest()
            request.predicate = NSPredicate(format: "locationID == %@", model.id as CVarArg)
            let locations = try context.fetch(request)
            locations.forEach(context.delete)
            try context.save()
        }
    }
}

public struct LocationModel: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let coordinate: CLLocationCoordinate2D
    
    public init(id: UUID, name: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
    }
    
    public static func == (lhs: LocationModel, rhs: LocationModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

extension LocationService: BaseProvider {
    public func fetch() async throws -> [LocationModel] {
        return try await fetchLocations()
    }
    
    public func fetchOne(id: UUID) async throws -> LocationModel? {
        let context = persistentContainer.viewContext
        let request = Location.fetchRequest()
        request.predicate = NSPredicate(format: "locationID == %@", id as CVarArg)
        
        return try await context.perform {
            guard let location = try request.execute().first else { return nil }
            return LocationModel(
                id: location.locationID ?? UUID(),
                name: location.name ?? "",
                coordinate: CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude?.doubleValue ?? 0.0
                )
            )
        }
    }
    
    public func save(_ item: LocationModel) async throws {
        try await saveLocation(item.name, coordinate: item.coordinate)
    }
    
    public func delete(_ item: LocationModel) async throws {
        try await deleteLocation(item)
    }
}
