//
//  SubHeading+CoreDataClass.swift
//  Hexagon
//
//  Created by Kieran Lynch on 08/11/2024.
//
//

import Foundation
import CoreData
import UniformTypeIdentifiers

@objc(SubHeading)
public class SubHeading: NSManagedObject, NSItemProviderReading {
    
    public static var readableTypeIdentifiersForItemProvider: [String] {
        [UTType("com.klynch.hexagon.subheading")?.identifier ?? "public.data"]
    }

    public required convenience init(context: NSManagedObjectContext, objectID: NSManagedObjectID) throws {
        guard let subHeading = try context.existingObject(with: objectID) as? SubHeading else {
            throw NSError(domain: "SubHeadingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize SubHeading with objectID"])
        }
        self.init(entity: subHeading.entity, insertInto: context)
        self.setValue(subHeading.objectID, forKey: "objectID")
    }

    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        let context = PersistenceController.shared.persistentContainer.viewContext
        guard let uri = URL(dataRepresentation: data, relativeTo: nil),
              let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri),
              let subHeading = try? context.existingObject(with: objectID) as? Self else {
            throw NSError(domain: "SubHeadingError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode SubHeading"])
        }
        return subHeading
    }
}
