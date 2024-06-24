import Foundation
import CoreData


extension ReminderPhoto {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReminderPhoto> {
        return NSFetchRequest<ReminderPhoto>(entityName: "ReminderPhoto")
    }

    @NSManaged public var photoData: Data?
    @NSManaged public var reminder: Reminder?

}

extension ReminderPhoto : Identifiable {

}
