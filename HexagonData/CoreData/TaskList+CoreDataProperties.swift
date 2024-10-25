//
//  TaskList+CoreDataProperties.swift
//  HexagonData
//
//  Created by Kieran Lynch on 20/10/2024.
//
//

import Foundation
import CoreData


extension TaskList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskList> {
        return NSFetchRequest<TaskList>(entityName: "TaskList")
    }

    @NSManaged public var colorData: Data?
    @NSManaged public var listID: UUID?
    @NSManaged public var name: String?
    @NSManaged public var order: Int16
    @NSManaged public var symbol: String?
    @NSManaged public var reminders: NSSet?
    @NSManaged public var subHeadings: NSSet?

}

// MARK: Generated accessors for reminders
extension TaskList {

    @objc(addRemindersObject:)
    @NSManaged public func addToReminders(_ value: Reminder)

    @objc(removeRemindersObject:)
    @NSManaged public func removeFromReminders(_ value: Reminder)

    @objc(addReminders:)
    @NSManaged public func addToReminders(_ values: NSSet)

    @objc(removeReminders:)
    @NSManaged public func removeFromReminders(_ values: NSSet)

}

// MARK: Generated accessors for subHeadings
extension TaskList {

    @objc(addSubHeadingsObject:)
    @NSManaged public func addToSubHeadings(_ value: SubHeading)

    @objc(removeSubHeadingsObject:)
    @NSManaged public func removeFromSubHeadings(_ value: SubHeading)

    @objc(addSubHeadings:)
    @NSManaged public func addToSubHeadings(_ values: NSSet)

    @objc(removeSubHeadings:)
    @NSManaged public func removeFromSubHeadings(_ values: NSSet)

}

extension TaskList : Identifiable {

}
