//
//  ReminderExtensions.swift
//  Hexagon
//
//  Created by Kieran Lynch on 17/09/2024.
//

import Foundation
import CoreData

extension Reminder {
    public var tagsArray: [ReminderTag] {
        let tagSet = tags as? Set<ReminderTag> ?? []
        return Array(tagSet)
    }
    
    public var photosArray: [ReminderPhoto] {
        let photoSet = photos as? Set<ReminderPhoto> ?? []
        return Array(photoSet)
    }
    
    public var notificationsArray: [String] {
        return notifications?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []
    }
}
