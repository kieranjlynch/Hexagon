//
//  TransferModels.swift
//  Hexagon
//
//  Created by Kieran Lynch on 22/11/2024.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

public enum ListItemType: String, Codable {
    case reminder
    case subheading
    case group
}

@objc public class ListItemTransfer: NSObject, Codable, Transferable, NSItemProviderWriting {
    public let id: UUID
    public let type: ListItemType
    public let subHeadingID: UUID?
    public let order: Int16
    public let title: String?
    public let isCompleted: Bool
    public let childReminderIDs: [UUID]
    
    public init(id: UUID, type: ListItemType, subHeadingID: UUID? = nil, order: Int16 = 0, title: String? = nil, isCompleted: Bool = false, childReminderIDs: [UUID] = []) {
        self.id = id
        self.type = type
        self.subHeadingID = subHeadingID
        self.order = order
        self.title = title
        self.isCompleted = isCompleted
        self.childReminderIDs = childReminderIDs
        super.init()
    }
    
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .hexagonListItem)
    }
    
    public static var writableTypeIdentifiersForItemProvider: [String] {
        [UTType.hexagonListItem.identifier]
    }
    
    public func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        do {
            let data = try PropertyListEncoder().encode(self)
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        return nil
    }
    
    public convenience init(from reminder: Reminder) {
        self.init(
            id: reminder.reminderID ?? UUID(),
            type: .reminder,
            subHeadingID: reminder.subHeading?.subheadingID,
            order: reminder.order,
            title: reminder.title,
            isCompleted: reminder.isCompleted,
            childReminderIDs: []
        )
    }
    
    public convenience init(from subHeading: SubHeading) {
        self.init(
            id: subHeading.subheadingID ?? UUID(),
            type: .subheading,
            subHeadingID: nil,
            order: subHeading.order,
            title: subHeading.title,
            isCompleted: false,
            childReminderIDs: (subHeading.reminders?.allObjects as? [Reminder] ?? [])
                .map { $0.reminderID ?? UUID() }
        )
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ListItemTransfer else { return false }
        return id == other.id && type == other.type
    }
    
    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(id)
        hasher.combine(type)
        return hasher.finalize()
    }
}

extension UTType {
    public static let hexagonListItem = UTType("com.hexagon.listitem")!
    public static let hexagonReminder = UTType("com.hexagon.reminder")!
    public static let hexagonSubheading = UTType("com.hexagon.subheading")!
}
