//
//  AppIntent.swift
//  HexagonWidget
//
//  Created by Kieran Lynch on 27/09/2024.
//

import WidgetKit
import AppIntents
import CoreData
import HexagonData

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("Choose a list to display tasks from.")

    @Parameter(title: "Select List", optionsProvider: WidgetListQuery())
    var selectedList: ListEntity?

    init() {}

    init(selectedList: ListEntity?) {
        self.selectedList = selectedList
    }

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

public struct ListEntity: AppEntity, Identifiable, Hashable {
    public let id: UUID
    public let name: String

    public static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "List")

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    public static var defaultQuery = WidgetListQuery()

    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}

public struct WidgetListQuery: EntityQuery {
    public init() {
        print("WidgetListQuery initialized")
    }
    
    public func entities(for identifiers: [UUID]) async throws -> [ListEntity] {
        print("entities(for:) called with identifiers: \(identifiers)")
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<TaskList> = TaskList.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "listID IN %@", identifiers)
        
        let taskLists = try context.fetch(fetchRequest)
        let entities = taskLists.compactMap { ListEntity(id: $0.listID!, name: $0.name ?? "Unnamed") }
        print("Returning \(entities.count) entities")
        return entities
    }
    
    public func suggestedEntities() async throws -> [ListEntity] {
        print("suggestedEntities() called")
        let context = PersistenceController.shared.newBackgroundContext()
        return try await context.perform {
            let fetchRequest: NSFetchRequest<TaskList> = TaskList.fetchRequest()
            let taskLists = try context.fetch(fetchRequest)
            let entities = taskLists.compactMap { taskList -> ListEntity? in
                guard let listID = taskList.listID else { return nil }
                return ListEntity(id: listID, name: taskList.name ?? "Unnamed")
            }
            print("Suggesting \(entities.count) entities")
            return entities
        }
    }
}
