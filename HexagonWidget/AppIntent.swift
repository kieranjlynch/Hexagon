//
//  AppIntent.swift
//  HexagonWidget
//
//  Created by Kieran Lynch on 04/10/2024.
//

import WidgetKit
import AppIntents
import SwiftUI
import HexagonData

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Task List Configuration"
    static var description: IntentDescription = IntentDescription("Choose a task list to display")

    @Parameter(title: "Task List")
    var taskList: TaskListEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Show tasks from \(\.$taskList)")
    }
}

struct TaskListEntity: AppEntity, Identifiable, TypeDisplayRepresentable, Equatable {
    let id: UUID
    let name: String
    
    static var defaultQuery = TaskListQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Task List")
    }
}

struct TaskListQuery: EntityQuery {
    typealias Entity = TaskListEntity
    
    func entities(for identifiers: [UUID]) async throws -> [TaskListEntity] {
        let taskLists = try await fetchTaskLists()
        return taskLists.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [TaskListEntity] {
        return try await fetchTaskLists()
    }

    func results() async throws -> [TaskListEntity] {
        return try await fetchTaskLists()
    }

    func defaultResult() async -> TaskListEntity? {
        return try? await fetchTaskLists().first
    }

    private func fetchTaskLists() async throws -> [TaskListEntity] {
        do {
            let taskLists = try await ListService.shared.updateTaskLists()
            let entities = taskLists.compactMap { taskList -> TaskListEntity? in
                guard let id = taskList.listID, let name = taskList.name else { return nil }
                return TaskListEntity(id: id, name: name)
            }
            return entities
        } catch {
            print("Error fetching task lists: \(error)")
            return []
        }
    }
}
