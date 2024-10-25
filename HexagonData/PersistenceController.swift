import Foundation
import CoreData
import os
import UIKit

public final class PersistenceController {
    public static let shared = PersistenceController()
    private let logger = Logger(subsystem: "com.klynch.Hexagon", category: "PersistenceController")

    public let persistentContainer: NSPersistentContainer
    private(set) var locations: [Location] = []

    private init(inMemory: Bool = false) {
        ValueTransformer.setValueTransformer(UIColorTransformer(), forName: NSValueTransformerName("UIColorTransformer"))

        let modelName = "HexagonModel"
        let bundle = Bundle(for: PersistenceController.self)

        guard let modelURL = bundle.url(forResource: modelName, withExtension: "momd") else {
            logger.error("Unable to locate Core Data model in bundle: \(bundle.bundlePath)")
            fatalError("Unable to locate Core Data model.")
        }

        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            logger.error("Unable to load Core Data model from URL: \(modelURL)")
            fatalError("Unable to load Core Data model.")
        }

        persistentContainer = NSPersistentContainer(name: modelName, managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            persistentContainer.persistentStoreDescriptions = [description]
        } else {
            guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.klynch.Hexagon") else {
                logger.error("Unable to find shared app group")
                fatalError("Unable to find shared app group")
            }
            let storeURL = appGroupURL.appendingPathComponent("HexagonModel.sqlite")
            let description = NSPersistentStoreDescription(url: storeURL)
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            persistentContainer.persistentStoreDescriptions = [description]
        }

        logger.debug("Persistent Store Description: \(self.persistentContainer.persistentStoreDescriptions)")

        persistentContainer.loadPersistentStores { storeDescription, error in
            if let error = error {
                self.logger.error("Failed to load persistent store: \(error.localizedDescription)")
                fatalError("Unresolved error \(error)")
            } else {
                self.logger.debug("Persistent store loaded successfully: \(storeDescription)")
                self.logger.debug("Store URL: \(storeDescription.url?.absoluteString ?? "unknown")")
                self.persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true

                do {
                    try self.persistentContainer.viewContext.setQueryGenerationFrom(.current)
                } catch {
                    self.logger.error("Failed to set query generation: \(error.localizedDescription)")
                }
            }
        }
    }

    public static func inMemoryController() -> PersistenceController {
        return PersistenceController(inMemory: true)
    }

    public func initialize() async throws {
        self.logger.debug("Core Data stack initialized")
        try await fetchLocations()
    }

    public func saveLocation(name: String, latitude: Double, longitude: Double) async throws {
        guard !persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty else {
            throw NSError(domain: "CoreDataError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Persistent store is not loaded."])
        }
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        try await context.perform {
            let location = Location(context: context)
            location.name = name
            location.latitude = latitude
            location.longitude = longitude

            if context.hasChanges {
                try context.save()
            }
        }

        try await fetchLocations()
    }

    public func fetchLocations() async throws {
        guard !persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty else {
            throw NSError(domain: "CoreDataError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Persistent store is not loaded."])
        }
        let context = persistentContainer.newBackgroundContext()
        let fetchedLocations = try await context.perform {
            let request: NSFetchRequest<Location> = Location.fetchRequest()
            return try context.fetch(request)
        }
        await MainActor.run {
            self.locations = fetchedLocations.map { location in
                let mainContext = self.persistentContainer.viewContext
                return mainContext.object(with: location.objectID) as! Location
            }
        }
    }

    public func saveContext() throws {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                logger.error("Error saving context: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    public func fetchPersistentHistory(since date: Date) throws -> [NSPersistentHistoryChange] {
        let request = NSPersistentHistoryChangeRequest.fetchHistory(after: date)
        let result = try persistentContainer.viewContext.execute(request) as? NSPersistentHistoryResult
        return result?.result as? [NSPersistentHistoryChange] ?? []
    }

    public func deletePersistentHistory(before date: Date) throws {
        let deleteHistoryRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: date)
        try persistentContainer.viewContext.execute(deleteHistoryRequest)
    }
}
