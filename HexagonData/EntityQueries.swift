//
//  EntityQueries.swift
//  Hexagon
//
//  Created by Kieran Lynch on 25/09/2024.
//

import Foundation
import AppIntents
import CoreData
import UIKit
import SwiftUI

public struct TaskListQuery: EntityQuery {
    public init() {}
    
    public func entities(for identifiers: [UUID]) async throws -> [TaskListEntity] {
        let taskLists = try await ReminderService.shared.updateTaskLists()
        return taskLists.compactMap { taskList -> TaskListEntity? in
            guard let listID = taskList.listID, identifiers.contains(listID) else {
                return nil
            }

            let taskListName = taskList.name ?? "Unnamed"
            let taskListSymbol = taskList.symbol ?? "default.symbol"

            let taskListColor: ColorEntity
            if let colorData = taskList.colorData {
                let color = decodeColor(from: colorData)
                taskListColor = ColorEntity(id: UUID(), color: color)
            } else {
                taskListColor = ColorEntity(id: UUID(), color: .gray)
            }
            return TaskListEntity(id: listID, name: taskListName, color: taskListColor, symbol: taskListSymbol)
        }
    }
    
    public func suggestedEntities() async throws -> [TaskListEntity] {
        let taskLists = try await ReminderService.shared.updateTaskLists()
        return taskLists.compactMap { taskList -> TaskListEntity? in
            guard let listID = taskList.listID else {
                return nil
            }
            let colorEntity: ColorEntity
            if let colorData = taskList.colorData {
                let color = decodeColor(from: colorData)
                colorEntity = ColorEntity(id: UUID(), color: color)
            } else {
                colorEntity = ColorEntity(id: UUID(), color: .gray)
            }
            
            return TaskListEntity(
                id: listID,
                name: taskList.name ?? "Unnamed",
                color: colorEntity,
                symbol: taskList.symbol ?? "default.symbol"
            )
        }
    }

    private func decodeColor(from colorData: Data) -> Color {
        if let uiColor = UIColorTransformer().reverseTransformedValue(colorData) as? UIColor {
            return Color(uiColor)
        } else {
            return Color.gray
        }
    }
}

public struct ReminderQuery: EntityQuery {
    public init() {}
    
    public func entities(for identifiers: [UUID]) async throws -> [ReminderEntity] {
        let reminders = try await ReminderService.shared.fetchAllReminders()
        
        return reminders.compactMap { reminder -> ReminderEntity? in
            guard let reminderID = reminder.reminderID, identifiers.contains(reminderID) else {
                return nil
            }
            return ReminderEntity(
                id: reminderID,
                title: reminder.title ?? "Untitled",
                isCompleted: reminder.isCompleted,
                dueDate: reminder.endDate
            )
        }
    }
    
    public func suggestedEntities() async throws -> [ReminderEntity] {
        let reminders = try await ReminderService.shared.fetchAllReminders()
        
        return reminders.compactMap { reminder -> ReminderEntity? in
            guard let reminderID = reminder.reminderID else {
                return nil
            }
            return ReminderEntity(
                id: reminderID,
                title: reminder.title ?? "Untitled",
                isCompleted: reminder.isCompleted,
                dueDate: reminder.endDate
            )
        }
    }
}

public struct TagQuery: EntityQuery {
    public init() {}
    
    public func entities(for identifiers: [UUID]) async throws -> [TagEntity] {
        let tags = try await ReminderService.shared.fetchTags()
        return tags
            .compactMap { tag in
                guard let tagID = tag.tagID, identifiers.contains(tagID) else {
                    return nil
                }
                return TagEntity(id: tagID, name: tag.name ?? "Unnamed Tag")
            }
    }
    
    public func suggestedEntities() async throws -> [TagEntity] {
        let tags = try await ReminderService.shared.fetchTags()
        return tags.compactMap { tag in
            guard let tagID = tag.tagID else {
                return nil
            }
            return TagEntity(id: tagID, name: tag.name ?? "Unnamed Tag")
        }
    }
}

public struct PriorityQuery: EntityQuery {
    public init() {}
    
    public func entities(for identifiers: [Int]) async throws -> [PriorityEntity] {
        let reminders = try await ReminderService.shared.fetchAllReminders()
        return reminders
            .compactMap { reminder in
                let priorityValue = Int(reminder.priority)
                if identifiers.contains(priorityValue) {
                    return PriorityEntity(id: priorityValue, name: "Priority \(priorityValue)")
                } else {
                    return nil
                }
            }
    }
    
    public func suggestedEntities() async throws -> [PriorityEntity] {
        let reminders = try await ReminderService.shared.fetchAllReminders()
        let priorities = Set(reminders.map { $0.priority })
        return priorities.map { PriorityEntity(id: Int($0), name: "Priority \($0)") }
    }
}

public struct LocationQuery: EntityQuery {
    public init() {}
    
    public func entities(for identifiers: [UUID]) async throws -> [LocationEntity] {
        let locations = try await ReminderService.shared.fetchLocations()
        return locations.compactMap { location in
            guard let locationID = location.locationID, identifiers.contains(locationID) else {
                return nil
            }
            return LocationEntity(
                id: locationID,
                name: location.name ?? "Unnamed Location",
                latitude: location.latitude,
                longitude: location.longitude
            )
        }
    }
    
    public func suggestedEntities() async throws -> [LocationEntity] {
        let locations = try await ReminderService.shared.fetchLocations()
        return locations.compactMap { location in
            guard let locationID = location.locationID, let name = location.name else {
                return nil
            }
            return LocationEntity(
                id: locationID,
                name: name,
                latitude: location.latitude,
                longitude: location.longitude
            )
        }
    }
}

public struct FocusFilterQuery: EntityQuery {
    public init() {}
    
    public func entities(for identifiers: [UUID]) async throws -> [FocusFilterEntity] {
        let focusFilters = try await ReminderService.shared.fetchFocusFilters()
        return focusFilters.filter { identifiers.contains($0.id) }
    }
    
    public func suggestedEntities() async throws -> [FocusFilterEntity] {
        return try await ReminderService.shared.fetchFocusFilters()
    }
}
