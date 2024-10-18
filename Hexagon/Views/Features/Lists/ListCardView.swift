//
//  ListCardView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import CoreData
import HexagonData

struct ListCardView: View {
    @Environment(\.appTintColor) var appTintColor
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var taskList: TaskList
    @EnvironmentObject private var reminderService: ReminderService
    @EnvironmentObject private var listService: ListService
    @Environment(\.colorScheme) var colorScheme
    @State private var isTargeted = false
    @State private var showEditView = false
    var onEdit: () -> Void
    var onDelete: () -> Void

    private var isInbox: Bool {
        taskList.name == "Inbox"
    }

    var body: some View {
        GroupBox {
            HStack(alignment: .center, spacing: 12) {
                listIcon
                listDetails
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 60) 
        .cardStyle()
        .scaleEffect(isTargeted ? 1.05 : 1.0)
        .animation(.spring(), value: isTargeted)
        .contextMenu { contextMenuContent }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(taskList.name ?? "Unnamed List")
        .accessibilityHint("Double-tap to view list options")
    }

    private var listIcon: some View {
        taskIconView(
            systemName: isInbox ? "tray.fill" : (taskList.symbol ?? "list.bullet"),
            label: "List Icon",
            hint: "Icon representing the task list",
            tintColor: isInbox ? .gray : Color(UIColor.color(data: taskList.colorData ?? Data()) ?? .gray)
        )
        .frame(width: 24, height: 24)
        .font(.system(size: 24))
    }

    private var listDetails: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(taskList.name ?? "Unnamed List")
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .accessibilityLabel("List name")
                .accessibilityValue(taskList.name ?? "Unnamed List")

            Text("\(incompleteRemindersCount) tasks")
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .accessibilityLabel("Task count")
                .accessibilityValue("\(incompleteRemindersCount) tasks")
        }
    }

    private var contextMenuContent: some View {
        Group {
            if !isInbox {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                        .accessibilityLabel("Edit List")
                        .accessibilityHint("Double-tap to edit the list")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                        .accessibilityLabel("Delete List")
                        .accessibilityHint("Double-tap to delete the list")
                }
            }
        }
    }

    private var incompleteRemindersCount: Int {
        guard let reminders = taskList.reminders?.allObjects as? [Reminder] else {
            return 0
        }
        return reminders.filter { !$0.isCompleted }.count
    }
}
