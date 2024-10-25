//
//  Location+CoreDataProperties.swift
//  HexagonData
//
//  Created by Kieran Lynch on 20/10/2024.
//
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var locationID: UUID?
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    @NSManaged public var reminder: Reminder?

}

extension Location : Identifiable {

}
