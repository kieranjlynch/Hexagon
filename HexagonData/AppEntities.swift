//
//  AppEntities.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import Foundation
import AppIntents
import SwiftUI
import os
import CoreData

public struct TaskListEntity: AppEntity, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let color: ColorEntity
    public let symbol: String
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Task List"
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    public static var defaultQuery = TaskListQuery()
}

public struct ReminderEntity: AppEntity, Identifiable {
    public let id: UUID
    public let title: String
    public let isCompleted: Bool
    public let dueDate: Date?
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Reminder"
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: title))
    }
    
    public static var defaultQuery = ReminderQuery()
}

public struct TagEntity: AppEntity, Identifiable {
    public let id: UUID
    public let name: String
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Tag"
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    public static var defaultQuery = TagQuery()
}

public struct PriorityEntity: AppEntity, Identifiable {
    public let id: Int
    public let name: String
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Priority"
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    public static var defaultQuery = PriorityQuery()
}

public struct LocationEntity: AppEntity, Identifiable {
    public let id: UUID
    public let name: String
    public let latitude: Double
    public let longitude: Double
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Location"
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    public static var defaultQuery = LocationQuery()
}

public struct FocusFilterEntity: AppEntity, Identifiable {
    public let id: UUID
    public let name: String
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Focus Filter"
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: name))
    }
    
    public static var defaultQuery = FocusFilterQuery()
}
