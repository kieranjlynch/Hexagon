//
//  TimelineModels.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/09/2024.
//

import Foundation
import CoreData
import EventKit

struct HashableTimelineTask: Hashable {
    let task: TimelineTask
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(task.id)
    }
    
    static func == (lhs: HashableTimelineTask, rhs: HashableTimelineTask) -> Bool {
        lhs.task.id == rhs.task.id
    }
}

public enum TimelineFilter: Hashable {
    case all
    case inbox
    case specificList(TaskList)
    
    var toServiceFilter: ListFilter {
        switch self {
        case .all:
            return .active
        case .inbox:
            return .active
        case .specificList(_):
            return .all
        }
    }
    
    public static func == (lhs: TimelineFilter, rhs: TimelineFilter) -> Bool {
        switch (lhs, rhs) {
        case (.all, .all):
            return true
        case (.inbox, .inbox):
            return true
        case (.specificList(let list1), .specificList(let list2)):
            return list1.listID == list2.listID
        default:
            return false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .all:
            hasher.combine(0)
        case .inbox:
            hasher.combine(1)
        case .specificList(let list):
            hasher.combine(2)
            hasher.combine(list.listID)
        }
    }
}

public struct TimelineTask: Identifiable, Equatable, Hashable {
    public let id: UUID
    public let title: String
    public let startDate: Date
    public let endDate: Date?
    public let listId: NSManagedObjectID?
    public var isCompleted: Bool
    public let isCalendarEvent: Bool
    
    public init(id: UUID, title: String, startDate: Date, endDate: Date?, list: TaskList?, isCompleted: Bool, isCalendarEvent: Bool = false) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.listId = list?.objectID
        self.isCompleted = isCompleted
        self.isCalendarEvent = isCalendarEvent
    }
    
    public init(from event: EKEvent) {
        self.id = UUID()
        self.title = event.title
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.listId = nil
        self.isCompleted = false
        self.isCalendarEvent = true
    }
    
    public var list: TaskList? {
        guard let listId = listId else { return nil }
        do {
            return try PersistenceController.shared.persistentContainer.viewContext.existingObject(with: listId) as? TaskList
        } catch {
            print("Failed to fetch TaskList: \(error.localizedDescription)")
            return nil
        }
    }
    
    public static func == (lhs: TimelineTask, rhs: TimelineTask) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.startDate == rhs.startDate &&
        lhs.endDate == rhs.endDate &&
        lhs.isCompleted == rhs.isCompleted &&
        lhs.listId == rhs.listId &&
        lhs.isCalendarEvent == rhs.isCalendarEvent
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(startDate)
        hasher.combine(endDate)
        hasher.combine(isCompleted)
        hasher.combine(listId)
        hasher.combine(isCalendarEvent)
    }
}
