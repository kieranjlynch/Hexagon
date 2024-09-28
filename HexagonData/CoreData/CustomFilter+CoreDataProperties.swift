//
//  CustomFilter+CoreDataProperties.swift
//  HexagonData
//
//  Created by Kieran Lynch on 27/09/2024.
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
