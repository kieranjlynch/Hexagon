//
//  Reminder+CoreDataClass.swift
//  Hexagon
//
//  Created by Kieran Lynch on 08/11/2024.
//
//

import Foundation
import CoreData
import UniformTypeIdentifiers

@objc(Reminder)
public class Reminder: NSManagedObject, NSItemProviderReading {
    
    public static var readableTypeIdentifiersForItemProvider: [String] {
        [UTType("com.klynch.hexagon.reminder")?.identifier ?? "public.data"]
    }
    
    public required convenience init(context: NSManagedObjectContext, objectID: NSManagedObjectID) throws {
        guard let reminder = try context.existingObject(with: objectID) as? Reminder else {
            throw NSError(domain: "ReminderError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize Reminder with objectID"])
        }
        self.init(entity: reminder.entity, insertInto: context)
        self.setValue(reminder.objectID, forKey: "objectID")
    }

    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        let context = PersistenceController.shared.persistentContainer.viewContext
        guard let uri = URL(dataRepresentation: data, relativeTo: nil),
              let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri),
              let reminder = try? context.existingObject(with: objectID) as? Self else {
            throw NSError(domain: "ReminderError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode Reminder"])
        }
        return reminder
    }
}
