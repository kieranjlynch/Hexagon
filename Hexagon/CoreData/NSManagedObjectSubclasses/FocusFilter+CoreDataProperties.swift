//
//  FocusFilter+CoreDataProperties.swift
//  Hexagon
//
//  Created by Kieran Lynch on 08/11/2024.
//
//

import Foundation
import CoreData


extension FocusFilter {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FocusFilter> {
        return NSFetchRequest<FocusFilter>(entityName: "FocusFilter")
    }

    @NSManaged public var focusFilterID: UUID?
    @NSManaged public var focusFilterName: String?

}

extension FocusFilter : Identifiable {

}
