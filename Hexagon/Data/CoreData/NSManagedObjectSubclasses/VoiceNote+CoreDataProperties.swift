//
//  VoiceNote+CoreDataProperties.swift
//  Hexagon
//
//  Created by Kieran Lynch on 08/11/2024.
//
//

import Foundation
import CoreData


extension VoiceNote {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VoiceNote> {
        return NSFetchRequest<VoiceNote>(entityName: "VoiceNote")
    }

    @NSManaged public var audioData: Data?
    @NSManaged public var reminder: Reminder?

}

extension VoiceNote : Identifiable {

}
