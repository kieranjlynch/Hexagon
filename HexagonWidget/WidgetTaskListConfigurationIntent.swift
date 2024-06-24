
//  WidgetTaskListConfigurationIntent.swift

import AppIntents
import SwiftUI
import SharedDataFramework

struct WidgetTaskListConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Task List Widget"
    static var description = IntentDescription("Choose a list or filter to display in the widget.")

    @Parameter(title: "List")
    var selectedList: TaskListEntity?

    @Parameter(title: "Filter")
    var selectedFilter: FilterType

    init() {
        selectedFilter = .all
    }

    init(selectedList: TaskListEntity?, selectedFilter: FilterType) {
        self.selectedList = selectedList
        self.selectedFilter = selectedFilter
    }

    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$selectedList
            \.$selectedFilter
        }
    }
}

enum FilterType: String, AppEnum {
    case all, today, scheduled, completed

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Filter Type"
    static var caseDisplayRepresentations: [FilterType: DisplayRepresentation] = [
        .all: "All",
        .today: "Today",
        .scheduled: "Scheduled",
        .completed: "Completed"
    ]
}

struct TaskListEntity: AppEntity {
    let id: String
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Task List"
    static var defaultQuery = TaskListQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct TaskListQuery: EntityQuery {
    func entities(for identifiers: [TaskListEntity.ID]) async throws -> [TaskListEntity] {
        let taskLists = ReminderService.getTaskLists()
        return taskLists.compactMap { taskList in
            guard let id = taskList.objectID.uriRepresentation().absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                  identifiers.contains(id) else {
                return nil
            }
            return TaskListEntity(id: id, name: taskList.name ?? "")
        }
    }

    func suggestedEntities() async throws -> [TaskListEntity] {
        let taskLists = ReminderService.getTaskLists()
        return taskLists.compactMap { taskList in
            guard let id = taskList.objectID.uriRepresentation().absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
                return nil
            }
            return TaskListEntity(id: id, name: taskList.name ?? "")
        }
    }
}
