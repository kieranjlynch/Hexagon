import Foundation
import CoreData
import UIKit

extension TaskList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskList> {
        return NSFetchRequest<TaskList>(entityName: "TaskList")
    }

    @NSManaged public var color: UIColor?
    @NSManaged public var name: String?
    @NSManaged public var symbol: String?
    @NSManaged public var order: Int16
    @NSManaged public var reminders: NSSet?

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

extension TaskList : Identifiable {

}
