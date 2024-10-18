//
//  PersistenceController.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import Foundation
import CoreData
import os
import UIKit
import CloudKit
import Combine

public final class PersistenceController {
    public static let shared = PersistenceController()
    private let logger = Logger(subsystem: "com.klynch.Hexagon", category: "PersistenceController")

    public let persistentContainer: NSPersistentCloudKitContainer
    @Published public private(set) var isCloudKitAvailable: Bool = false

    private init(inMemory: Bool = false) {
        ValueTransformer.setValueTransformer(UIColorTransformer(), forName: NSValueTransformerName("UIColorTransformer"))

        let modelName = "HexagonModel"
        let bundle = Bundle(for: type(of: self))

        logger.debug("Bundle path: \(bundle.bundlePath)")

        guard let modelURL = bundle.url(forResource: modelName, withExtension: "momd") else {
            logger.error("Unable to locate Core Data model in bundle: \(bundle.bundlePath)")
            fatalError("Unable to locate Core Data model.")
        }

        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            logger.error("Unable to load Core Data model from URL: \(modelURL)")
            fatalError("Unable to load Core Data model.")
        }

        persistentContainer = NSPersistentCloudKitContainer(name: modelName, managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            persistentContainer.persistentStoreDescriptions = [description]
        } else {
            guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.klynch.Hexagon") else {
                logger.error("Unable to find shared app group")
                fatalError("Unable to find shared app group")
            }
            let storeURL = appGroupURL.appendingPathComponent("HexagonModel.sqlite")
            let description = NSPersistentStoreDescription(url: storeURL)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

            let cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.klynch.Hexagon")
            description.cloudKitContainerOptions = cloudKitContainerOptions

            persistentContainer.persistentStoreDescriptions = [description]
        }

        logger.debug("Persistent Store Description: \(self.persistentContainer.persistentStoreDescriptions)")

        persistentContainer.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                self.logger.error("Failed to load persistent store: \(error.localizedDescription)")
            } else {
                self.logger.debug("Persistent store loaded successfully: \(storeDescription)")
                Task {
                    await self.checkCloudKitAvailability()
                }
            }

            self.persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        }

        NotificationCenter.default.addObserver(self, selector: #selector(handleCloudKitEvent(_:)), name: NSPersistentCloudKitContainer.eventChangedNotification, object: nil)
    }

    private func checkCloudKitAvailability() async {
        do {
            let accountStatus = try await CKContainer.default().accountStatus()
            await MainActor.run {
                self.isCloudKitAvailable = (accountStatus == .available)
                self.logger.debug("CloudKit availability: \(self.isCloudKitAvailable)")
            }
        } catch {
            self.logger.error("Failed to check CloudKit availability: \(error.localizedDescription)")
        }
    }

    public func initialize() async throws {
        self.logger.debug("Core Data stack initialized")
        if persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
            throw NSError(domain: "CoreDataError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Persistent store is not loaded."])
        }

        #if DEBUG
        Task {
            do {
                try persistentContainer.initializeCloudKitSchema(options: [])
                logger.debug("CloudKit schema initialized successfully")
            } catch {
                logger.error("Failed to initialize CloudKit schema: \(error.localizedDescription)")
            }
        }
        #endif
    }

    public static func inMemoryController() -> PersistenceController {
        return PersistenceController(inMemory: true)
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
    }

    public func fetchLocations() async throws -> [Location] {
        guard !persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty else {
            throw NSError(domain: "CoreDataError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Persistent store is not loaded."])
        }
        let context = persistentContainer.newBackgroundContext()
        return try await context.perform {
            let request: NSFetchRequest<Location> = Location.fetchRequest()
            return try context.fetch(request)
        }
    }

    public func saveContext() throws {
        let context = persistentContainer.newBackgroundContext()
        context.performAndWait {
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    self.logger.error("Error saving context: \(error.localizedDescription)")
                }
            }
        }
    }
    
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    @objc private func handleCloudKitEvent(_ notification: Notification) {
        DispatchQueue.main.async {
            guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
                return
            }

            let isFinished = event.endDate != nil
            
            switch (event.type, isFinished) {
            case (.import, false):
                self.logger.debug("Started downloading records")
            case (.import, true):
                self.logger.debug("Finished downloading records")
                Task {
                    try? await ListService.shared.ensureInboxListExists()
                }
            case (.export, false):
                self.logger.debug("Started uploading records")
            case (.export, true):
                self.logger.debug("Finished uploading records")
            case (.setup, _):
                self.logger.debug("Setup event: \(isFinished ? "finished" : "started")")
            @unknown default:
                self.logger.debug("Unknown event type: \(String(describing: event.type)), finished: \(isFinished)")
            }

            if let error = event.error {
                self.handleCloudKitError(error)
            }
        }
    }


    private func handleCloudKitError(_ error: Error) {
        if let cloudKitError = error as? CKError {
            switch cloudKitError.code {
            case .quotaExceeded:
                logger.error("iCloud quota exceeded")
            case .partialFailure:
                logger.error("Partial failure in CloudKit operation")
            default:
                logger.error("CloudKit error: \(cloudKitError.localizedDescription)")
            }
        } else {
            let nsError = error as NSError
            switch nsError.code {
            case 134400:
                logger.error("Not logged in to iCloud")
            case 134419:
                logger.error("Too much work to do")
            default:
                logger.error("Unknown error: \(nsError.localizedDescription)")
            }
        }
    }
}
