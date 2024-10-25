//
//  VoiceNote+CoreDataProperties.swift
//  HexagonData
//
//  Created by Kieran Lynch on 20/10/2024.
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
