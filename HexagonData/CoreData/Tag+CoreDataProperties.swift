//
//  Tag+CoreDataProperties.swift
//  HexagonData
//
//  Created by Kieran Lynch on 27/09/2024.
//
//

import Foundation
import CoreData

extension Tag {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: "Tag")
    }

    @NSManaged public var name: String?
    @NSManaged public var tagID: UUID?
    @NSManaged public var reminders: NSSet?
}

// MARK: Generated accessors for reminders
extension Tag {
    @objc(addRemindersObject:)
    @NSManaged public func addToReminders(_ value: Reminder)

    @objc(removeRemindersObject:)
    @NSManaged public func removeFromReminders(_ value: Reminder)

    @objc(addReminders:)
    @NSManaged public func addToReminders(_ values: NSSet)

    @objc(removeReminders:)
    @NSManaged public func removeFromReminders(_ values: NSSet)
}

extension Tag: Identifiable {
}

extension Tag {
    public func isEqual(to other: Tag) -> Bool {
        return self.tagID == other.tagID
    }
}
