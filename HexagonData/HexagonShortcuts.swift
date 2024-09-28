//
//  HexagonShortcuts.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import Foundation
import AppIntents

struct HexagonShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddNewTaskIntent(),
            phrases: [
                "Add a new task to Hexagon",
                "Create a task in Hexagon",
                "New task for Hexagon"
            ],
            shortTitle: "Add Task",
            systemImageName: "plus.circle"
        )
        
        AppShortcut(
            intent: MarkTaskCompleteIntent(),
            phrases: [
                "Mark task as complete in Hexagon",
                "Complete a task in Hexagon",
                "Finish a task in Hexagon"
            ],
            shortTitle: "Complete Task",
            systemImageName: "checkmark.circle"
        )
        
        AppShortcut(
            intent: AddNewListIntent(),
            phrases: [
                "Add a new list to Hexagon",
                "Create a list in Hexagon",
                "New list for Hexagon"
            ],
            shortTitle: "Add List",
            systemImageName: "list.bullet.circle"
        )
        
        AppShortcut(
            intent: MoveTaskIntent(),
            phrases: [
                "Move a task in Hexagon",
                "Change task list in Hexagon",
                "Relocate task in Hexagon"
            ],
            shortTitle: "Move Task",
            systemImageName: "arrow.right.circle"
        )
        
        AppShortcut(
            intent: GetTasksFromListIntent(),
            phrases: [
                "Show tasks from a list in Hexagon",
                "Get tasks from Hexagon",
                "List tasks in Hexagon"
            ],
            shortTitle: "Show Tasks",
            systemImageName: "list.bullet"
        )
        
        AppShortcut(
            intent: ToggleTaskCompletionIntent(),
            phrases: [
                "Toggle completion of a task in Hexagon",
                "Change task status in Hexagon",
                "Update a task's completion in Hexagon"
            ],
            shortTitle: "Toggle Task Completion",
            systemImageName: "arrow.uturn.left.circle"
        )
    }
}
