@preconcurrency import SwiftUI
@preconcurrency import CoreData
@preconcurrency 
import os


struct ListCardView: View {
    @Environment(\.appTintColor) var appTintColor
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var taskList: TaskList
    @EnvironmentObject private var fetchingService: ReminderFetchingServiceUI
    @EnvironmentObject private var modificationService: ReminderModificationService
    @EnvironmentObject private var listService: ListService
    @Environment(\.colorScheme) var colorScheme
    @State private var isTargeted = false
    @State private var reminderCount: Int = 0
    @State private var showEditView = false
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    private let cardHeight: CGFloat = 40
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.hexagon", category: "ListCardView")
    
    var body: some View {
        mainContent
            .frame(height: cardHeight)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .adaptiveBackground()
            .cornerRadius(Constants.UI.cornerRadius)
            .adaptiveShadow()
            .scaleEffect(isTargeted ? 1.05 : 1.0)
            .animation(.spring(), value: isTargeted)
            .task {
                await updateReminderCount()
            }
            .onChange(of: taskList.reminders?.count) { _, _ in
                Task {
                    await updateReminderCount()
                }
            }
            .contextMenu { contextMenuContent }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(taskList.name ?? "Unnamed List")
            .accessibilityHint("Double-tap to view list options")
    }
    
    private var mainContent: some View {
        HStack {
            listIcon
            listDetails
            Spacer()
        }
    }
    
    private var listIcon: some View {
        taskIconView(
            systemName: taskList.symbol ?? "list.bullet",
            label: "List Icon",
            hint: "Icon representing the task list",
            tintColor: Color(UIColor.color(data: taskList.colorData ?? Data()) ?? .gray)
        )
        .font(.system(size: 24))
        .padding(.horizontal, 8)
    }
    
    private var listDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(taskList.name ?? "Unnamed List")
                .adaptiveColors()
                .font(.headline)
                .accessibilityLabel("List name")
                .accessibilityValue(taskList.name ?? "Unnamed List")
            
            Text("\(reminderCount) tasks")
                .adaptiveColors()
                .font(.caption)
                .accessibilityLabel("Task count")
                .accessibilityValue("\(reminderCount) tasks")
        }
    }
    
    private var contextMenuContent: some View {
        Group {
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

    private func updateReminderCount() async {
        let count = await fetchingService.getIncompleteRemindersCount(for: taskList)
        await MainActor.run {
            reminderCount = count
        }
    }
}
