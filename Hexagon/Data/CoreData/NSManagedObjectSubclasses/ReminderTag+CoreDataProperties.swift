//
//  ReminderTag+CoreDataProperties.swift
//  Hexagon
//
//  Created by Kieran Lynch on 08/11/2024.
//
//

import Foundation
import CoreData


extension ReminderTag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReminderTag> {
        return NSFetchRequest<ReminderTag>(entityName: "ReminderTag")
    }

    @NSManaged public var name: String?
    @NSManaged public var tagID: UUID?
    @NSManaged public var reminders: NSSet?

}

// MARK: Generated accessors for reminders
extension ReminderTag {

    @objc(addRemindersObject:)
    @NSManaged public func addToReminders(_ value: Reminder)

    @objc(removeRemindersObject:)
    @NSManaged public func removeFromReminders(_ value: Reminder)

    @objc(addReminders:)
    @NSManaged public func addToReminders(_ values: NSSet)

    @objc(removeReminders:)
    @NSManaged public func removeFromReminders(_ values: NSSet)

}

extension ReminderTag : Identifiable {

}
