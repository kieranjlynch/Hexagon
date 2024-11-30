//
//  DataTypes.swift
//  Hexagon
//
//  Created by Kieran Lynch on 17/11/2024.
//

import Foundation

public enum ListFilter: Sendable {
    case all
    case completed
    case active
}

public struct PredicateRepresentation: @unchecked Sendable {
    public let format: String
    public let arguments: [Any]
    
    public init(format: String, arguments: [Any]) {
        self.format = format
        self.arguments = arguments
    }
    
    public func toNSPredicate() -> NSPredicate {
        NSPredicate(format: format, argumentArray: arguments)
    }
}

public struct SortDescriptorRepresentation: Sendable {
    public let key: String
    public let ascending: Bool
    
    public init(key: String, ascending: Bool) {
        self.key = key
        self.ascending = ascending
    }
    
    public func toNSSortDescriptor() -> NSSortDescriptor {
        NSSortDescriptor(key: key, ascending: ascending)
    }
}
