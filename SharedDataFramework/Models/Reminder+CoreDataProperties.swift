import Foundation
import CoreData


extension Reminder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Reminder> {
        return NSFetchRequest<Reminder>(entityName: "Reminder")
    }

    @NSManaged public var endDate: Date?
    @NSManaged public var identifier: UUID?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var notes: String?
    @NSManaged public var priority: Int16
    @NSManaged public var radius: Double
    @NSManaged public var reminderTime: Date?
    @NSManaged public var startDate: Date?
    @NSManaged public var tag: String?
    @NSManaged public var title: String?
    @NSManaged public var url: String?
    @NSManaged public var list: TaskList?
    @NSManaged public var location: Location?
    @NSManaged public var photos: NSSet?
    @NSManaged public var tags: Tag?

}

// MARK: Generated accessors for photos
extension Reminder {

    @objc(addPhotosObject:)
    @NSManaged public func addToPhotos(_ value: ReminderPhoto)

    @objc(removePhotosObject:)
    @NSManaged public func removeFromPhotos(_ value: ReminderPhoto)

    @objc(addPhotos:)
    @NSManaged public func addToPhotos(_ values: NSSet)

    @objc(removePhotos:)
    @NSManaged public func removeFromPhotos(_ values: NSSet)

}

extension Reminder : Identifiable {

}
