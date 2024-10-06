//
//  SubHeading+CoreDataProperties.swift
//  HexagonData
//
//  Created by Kieran Lynch on 06/10/2024.
//
//

import Foundation
import CoreData


extension SubHeading {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SubHeading> {
        return NSFetchRequest<SubHeading>(entityName: "SubHeading")
    }

    @NSManaged public var order: Int16
    @NSManaged public var subheadingID: UUID?
    @NSManaged public var title: String?
    @NSManaged public var reminders: NSSet?
    @NSManaged public var taskList: TaskList?

}

// MARK: Generated accessors for reminders
extension SubHeading {

    @objc(addRemindersObject:)
    @NSManaged public func addToReminders(_ value: Reminder)

    @objc(removeRemindersObject:)
    @NSManaged public func removeFromReminders(_ value: Reminder)

    @objc(addReminders:)
    @NSManaged public func addToReminders(_ values: NSSet)

    @objc(removeReminders:)
    @NSManaged public func removeFromReminders(_ values: NSSet)

}

extension SubHeading : Identifiable {

}
