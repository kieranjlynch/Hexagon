//
//  Reminder+CoreDataProperties.swift
//  Hexagon
//
//  Created by Kieran Lynch on 14/10/2024.
//
//

import Foundation
import CoreData

extension Reminder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Reminder> {
        return NSFetchRequest<Reminder>(entityName: "Reminder")
    }

    @NSManaged public var endDate: Date?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var isInInbox: Bool
    @NSManaged public var notes: String?
    @NSManaged public var notifications: String?
    @NSManaged public var order: Int16
    @NSManaged public var priority: Int16
    @NSManaged public var radius: NSNumber?
    @NSManaged public var reminderID: UUID?
    @NSManaged public var reminderTime: Date?
    @NSManaged public var startDate: Date?
    @NSManaged public var tag: String?
    @NSManaged public var title: String?
    @NSManaged public var url: String?
    @NSManaged public var list: TaskList?
    @NSManaged public var location: Location?
    @NSManaged public var photos: NSSet?
    @NSManaged public var subHeading: SubHeading?
    @NSManaged public var tags: NSSet?
    @NSManaged public var voiceNote: VoiceNote?

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

// MARK: Generated accessors for tags
extension Reminder {

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: ReminderTag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: ReminderTag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)

}

extension Reminder : Identifiable {

}
