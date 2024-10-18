//
//  Transferable+CoreDataEntities.swift
//  Hexagon
//
//  Created by Kieran Lynch on 27/09/2024.
//

import Foundation
import UniformTypeIdentifiers
import CoreData
import SwiftUI
import HexagonData

extension SubHeading: @retroactive Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .hexagonSubHeading) { subHeading in
            guard let data = subHeading.objectID.uriRepresentation().absoluteString.data(using: .utf8) else {
                throw NSError(domain: "SubHeadingTransferError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode SubHeading ID"])
            }
            return data
        } importing: { data in
            guard let uriString = String(data: data, encoding: .utf8),
                  let uri = URL(string: uriString) else {
                throw NSError(domain: "SubHeadingTransferError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode SubHeading URI"])
            }
            
            let context = PersistenceController.shared.persistentContainer.viewContext
            guard let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
                throw NSError(domain: "SubHeadingTransferError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create object ID"])
            }
            
            do {
                let subHeading = try context.existingObject(with: objectID)
                guard let typedSubHeading = subHeading as? SubHeading else {
                    throw NSError(domain: "SubHeadingTransferError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Object is not a SubHeading"])
                }
                return typedSubHeading
            } catch {
                throw NSError(domain: "SubHeadingTransferError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to load SubHeading: \(error.localizedDescription)"])
            }
        }
    }
}

extension Reminder: @retroactive Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .hexagonReminder) { reminder in
            guard let data = reminder.objectID.uriRepresentation().absoluteString.data(using: .utf8) else {
                throw NSError(domain: "ReminderTransferError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode Reminder ID"])
            }
            return data
        } importing: { data in
            guard let uriString = String(data: data, encoding: .utf8),
                  let uri = URL(string: uriString) else {
                throw NSError(domain: "ReminderTransferError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode Reminder URI"])
            }
            
            let context = PersistenceController.shared.persistentContainer.viewContext
            guard let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
                throw NSError(domain: "ReminderTransferError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create object ID"])
            }
            
            do {
                let reminder = try context.existingObject(with: objectID)
                guard let typedReminder = reminder as? Reminder else {
                    throw NSError(domain: "ReminderTransferError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Object is not a Reminder"])
                }
                return typedReminder
            } catch {
                throw NSError(domain: "ReminderTransferError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to load Reminder: \(error.localizedDescription)"])
            }
        }
    }
}

extension UTType {
    public static let hexagonSubHeading = UTType(exportedAs: "com.klynch.hexagon.subheading")
    public static let hexagonReminder = UTType(exportedAs: "com.klynch.hexagon.reminder")
}
