//
//  AppIntent.swift
//  HexagonWidget
//
//  Created by Kieran Lynch on 04/10/2024.
//

import WidgetKit
import AppIntents
import SwiftUI

@available(iOS 16.0, macOS 13.0, watchOS 9.0, *)
public struct ConfigurationAppIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource = "Task List Configuration"
    public static var description = IntentDescription("Choose a task list to display")

    @Parameter(title: "List", description: "Select which task list to display")
    public var taskList: TaskListEntity?
    
    public init() {}
    
    public init(taskList: TaskListEntity? = nil) {
        self.taskList = taskList
    }

    public static var parameterSummary: some ParameterSummary {
        Summary {
            \.$taskList
        }
    }
}

public struct TaskListEntity: AppEntity {
    public let id: UUID
    public let name: String
    
    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Task List"
    public static let defaultQuery = TaskListQuery()
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

public struct TaskListQuery: EntityStringQuery, DynamicOptionsProvider {
    public init() {}
    
    private static var cachedLists: [TaskListEntity] = []
    private static var cacheTimestamp: Date?
    private static let cacheLifetime: TimeInterval = 300
    
    private static func isCacheValid() -> Bool {
        guard let timestamp = cacheTimestamp else { return false }
        return Date().timeIntervalSince(timestamp) < cacheLifetime
    }
    
    @MainActor
    public func suggestedEntities() async throws -> [TaskListEntity] {
        await Self.updateCache()
        return Self.cachedLists
    }
    
    public func defaultResult() async throws -> TaskListEntity? {
        await Self.updateCache()
        return Self.cachedLists.first
    }
    
    public func entities(matching string: String) async throws -> [TaskListEntity] {
        await Self.updateCache()
        return Self.cachedLists.filter { list in
            string.isEmpty || list.name.localizedCaseInsensitiveContains(string)
        }
    }
    
    public func entities(for identifiers: [UUID]) async throws -> [TaskListEntity] {
        await Self.updateCache()
        return Self.cachedLists.filter { list in
            identifiers.contains(list.id)
        }
    }
    
    @MainActor
    public static func updateCache() async {
        if isCacheValid() { return }
        
        do {
            try await PersistenceController.shared.initialize()
            let listService = ListService.shared
            await listService.initialize()
            let taskLists = try await listService.fetchAllLists()
            
            let sortedLists = taskLists.sorted(by: { first, second in
                let firstDate = first.createdAt ?? Date.distantPast
                let secondDate = second.createdAt ?? Date.distantPast
                return firstDate > secondDate
            })
            
            Self.cachedLists = sortedLists.compactMap { list in
                guard let id = list.listID,
                      let name = list.name else {
                    return nil
                }
                return TaskListEntity(id: id, name: name)
            }
            
            Self.cacheTimestamp = Date()
            
            WidgetCenter.shared.reloadTimelines(ofKind: "HexagonWidget")
        } catch {
            Self.cacheTimestamp = nil
        }
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, *)
public struct HexagonIntentsPackage: AppIntentsPackage {
    public static var appIntents: [any AppIntent.Type] {
        [
            ConfigurationAppIntent.self
        ]
    }
}
