//
//  ReminderPhoto+CoreDataProperties.swift
//  Hexagon
//
//  Created by Kieran Lynch on 08/11/2024.
//
//

import Foundation
import CoreData


extension ReminderPhoto {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReminderPhoto> {
        return NSFetchRequest<ReminderPhoto>(entityName: "ReminderPhoto")
    }

    @NSManaged public var order: Int16
    @NSManaged public var photoData: Data?
    @NSManaged public var reminder: Reminder?

}

extension ReminderPhoto : Identifiable {

}
