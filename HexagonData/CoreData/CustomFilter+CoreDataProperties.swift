//
//  CustomFilter+CoreDataProperties.swift
//  Hexagon
//
//  Created by Kieran Lynch on 14/10/2024.
//
//

import Foundation
import CoreData


extension CustomFilter {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CustomFilter> {
        return NSFetchRequest<CustomFilter>(entityName: "CustomFilter")
    }

    @NSManaged public var name: String?
    @NSManaged public var query: String?

}

extension CustomFilter : Identifiable {

}
