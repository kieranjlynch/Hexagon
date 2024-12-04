//
//  PersistenceController.swift
//  Hexagon
//
//  Created by Kieran Lynch on 03/10/2024.
//

import Foundation
import CoreData
import os
import UIKit

public final class PersistenceController {
    public static let shared = PersistenceController()
    private let logger = Logger(subsystem: "com.klynch.Hexagon", category: "PersistenceController")
    public private(set) var persistentContainer: NSPersistentContainer!
    private var historyToken: NSPersistentHistoryToken?
    private let modelName = "HexagonModel"
    private let appGroupIdentifier = "group.com.klynch.Hexagon"
    private static let historyTrackingTokenKey = "PersistentHistoryTracker.lastToken"
    private var isInitialized = false
    private var initializationTask: Task<Void, Error>?
    private let lock = NSRecursiveLock()
    
    private init(inMemory: Bool = false) {
        setupContainer(inMemory: inMemory)
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(persistentStoreRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: persistentContainer.persistentStoreCoordinator
        )
    }
    
    @objc private func persistentStoreRemoteChange(_ notification: Notification) {
        Task {
            do {
                try await processRemoteStoreChange()
            } catch {
                logger.error("Failed to process remote store change: \(error.localizedDescription)")
            }
        }
    }
    
    private func processRemoteStoreChange() async throws {
        let context = persistentContainer.viewContext
        let fetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: historyToken)
        
        if let transactions = try await context.perform({ () -> [NSPersistentHistoryTransaction]? in
            let result = try context.execute(fetchRequest) as? NSPersistentHistoryResult
            return result?.result as? [NSPersistentHistoryTransaction]
        }) {
            await MainActor.run {
                for transaction in transactions {
                    context.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
                    historyToken = transaction.token
                    try? persistHistoryToken(transaction.token)
                }
            }
        }
    }
    
    private func setupContainer(inMemory: Bool) {
        ValueTransformer.setValueTransformer(UIColorTransformer(), forName: NSValueTransformerName("UIColorTransformer"))
        
        let model = loadManagedObjectModel()
        let container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        let description = createStoreDescription(inMemory: inMemory)
        
        container.persistentStoreDescriptions = [description]
        self.persistentContainer = container
    }
    
    private func loadManagedObjectModel() -> NSManagedObjectModel {
        if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd"),
           let model = NSManagedObjectModel(contentsOf: modelURL) {
            return model
        }
        
        if let model = NSManagedObjectModel.mergedModel(from: [Bundle(for: PersistenceController.self)]) {
            return model
        }
        
        logger.error("Unable to locate or load Core Data model")
        fatalError("Core Data model configuration error")
    }
    
    private func createStoreDescription(inMemory: Bool) -> NSPersistentStoreDescription {
        let description: NSPersistentStoreDescription
        
        if inMemory {
            description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
        } else {
            guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
                logger.error("Unable to find shared app group")
                fatalError("App Group configuration error")
            }
            
            let storeURL = appGroupURL.appendingPathComponent("\(modelName).sqlite")
            description = NSPersistentStoreDescription(url: storeURL)
        }
        
        description.type = NSSQLiteStoreType
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.shouldAddStoreAsynchronously = true
        
        return description
    }
    
    public static func inMemoryController() -> PersistenceController {
        return PersistenceController(inMemory: true)
    }
    
    public func initialize() async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    if isInitialized {
                        continuation.resume()
                        return
                    }
                    
                    if let existingTask = initializationTask {
                        try await existingTask.value
                        continuation.resume()
                        return
                    }
                    
                    let task = Task {
                        return try await withCheckedThrowingContinuation { (innerContinuation: CheckedContinuation<Void, Error>) in
                            persistentContainer.loadPersistentStores { [weak self] description, error in
                                guard let self = self else {
                                    innerContinuation.resume(throwing: CoreDataError.storeConfigurationFailed)
                                    return
                                }
                                
                                if let error = error {
                                    self.logger.error("Failed to load persistent store: \(error.localizedDescription)")
                                    innerContinuation.resume(throwing: error)
                                    return
                                }
                                
                                self.setupContextsAndHistory()
                                self.isInitialized = true
                                
                                Task {
                                    do {
                                        try await self.processHistoryIfNeeded()
                                        innerContinuation.resume()
                                    } catch {
                                        innerContinuation.resume(throwing: error)
                                    }
                                }
                            }
                        }
                    }
                    
                    initializationTask = task
                    try await task.value
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func setupContextsAndHistory() {
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        
        do {
            try persistentContainer.viewContext.setQueryGenerationFrom(.current)
        } catch {
            logger.error("Failed to set query generation: \(error.localizedDescription)")
        }
        
        loadHistoryToken()
    }
    
    private func loadHistoryToken() {
        guard let tokenData = UserDefaults.standard.data(forKey: PersistenceController.historyTrackingTokenKey) else {
            return
        }
        
        do {
            historyToken = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSPersistentHistoryToken.self,
                from: tokenData
            )
        } catch {
            logger.error("Failed to unarchive history token: \(error.localizedDescription)")
        }
    }
    
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    public func performBackgroundTask<T>(block: @escaping (NSManagedObjectContext) -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                let result = block(context)
                continuation.resume(returning: result)
            }
        }
    }
    
    public func performBackgroundTaskWithThrows<T>(block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func saveContext() async throws {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                try await processHistoryIfNeeded()
            } catch {
                logger.error("Error saving context: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    private func processHistoryIfNeeded() async throws {
        guard let lastToken = historyToken else {
            try await processAllHistory()
            return
        }
        
        let context = persistentContainer.newBackgroundContext()
        let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastToken)
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    guard let historyResult = try context.execute(request) as? NSPersistentHistoryResult,
                          let transactions = historyResult.result as? [NSPersistentHistoryTransaction] else {
                        self.logger.error("Failed to fetch history transactions")
                        continuation.resume()
                        return
                    }
                    
                    Task { @MainActor in
                        for transaction in transactions {
                            self.persistentContainer.viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
                            self.historyToken = transaction.token
                            do {
                                try self.persistHistoryToken(transaction.token)
                            } catch {
                                self.logger.error("Failed to persist history token: \(error.localizedDescription)")
                            }
                        }
                        
                        do {
                            try await self.cleanupOldHistory()
                            continuation.resume()
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func processAllHistory() async throws {
        let context = persistentContainer.newBackgroundContext()
        let request = NSPersistentHistoryChangeRequest.fetchHistory(after: Date.distantPast)
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    guard let historyResult = try context.execute(request) as? NSPersistentHistoryResult,
                          let transactions = historyResult.result as? [NSPersistentHistoryTransaction],
                          let lastTransaction = transactions.last else {
                        continuation.resume()
                        return
                    }
                    
                    Task { @MainActor in
                        self.historyToken = lastTransaction.token
                        do {
                            try self.persistHistoryToken(lastTransaction.token)
                            continuation.resume()
                        } catch {
                            self.logger.error("Failed to persist history token: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func cleanupOldHistory() async throws {
        let calendar = Calendar.current
        guard let oldestDate = calendar.date(byAdding: .day, value: -7, to: Date()) else { return }
        
        let context = persistentContainer.newBackgroundContext()
        let deleteRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: oldestDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    try context.execute(deleteRequest)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func persistHistoryToken(_ token: NSPersistentHistoryToken) throws {
        guard let tokenData = try? NSKeyedArchiver.archivedData(
            withRootObject: token,
            requiringSecureCoding: true
        ) else {
            throw CoreDataError.historyTrackingFailed
        }
        
        UserDefaults.standard.set(tokenData, forKey: PersistenceController.historyTrackingTokenKey)
    }
}

extension PersistenceController {
    enum CoreDataError: LocalizedError {
        case modelNotFound
        case storeConfigurationFailed
        case historyTrackingFailed
        
        var errorDescription: String? {
            switch self {
            case .modelNotFound:
                return "Failed to locate or load Core Data model"
            case .storeConfigurationFailed:
                return "Failed to configure persistent store"
            case .historyTrackingFailed:
                return "Failed to process persistent history"
            }
        }
    }
}

extension PersistenceController {
    @MainActor
    func objectID(for uri: URL) -> NSManagedObjectID? {
        persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: uri)
    }
    
    @MainActor
    func existingObject<T: NSManagedObject>(with objectID: NSManagedObjectID, as type: T.Type) -> T? {
        return try? persistentContainer.viewContext.existingObject(with: objectID) as? T
    }
}
