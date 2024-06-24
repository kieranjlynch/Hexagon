
//  HexagonWidget.swift

import WidgetKit
import SwiftUI
import SharedDataFramework

struct HexagonWidget: Widget {
    let kind: String = "HexagonWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WidgetTaskListConfigurationIntent.self, provider: Provider()) { entry in
            HexagonWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Hexagon TaskManager")
        .description("Display tasks from Hexagon by List or Filter.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: WidgetTaskListConfigurationIntent(), reminders: [])
    }

    func snapshot(for configuration: WidgetTaskListConfigurationIntent, in context: Context) async -> SimpleEntry {
        let reminders = fetchReminders(for: configuration)
        return SimpleEntry(date: Date(), configuration: configuration, reminders: reminders)
    }
    
    func timeline(for configuration: WidgetTaskListConfigurationIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let reminders = fetchReminders(for: configuration)
        let entry = SimpleEntry(date: Date(), configuration: configuration, reminders: reminders)
        return Timeline(entries: [entry], policy: .atEnd)
    }
    
    private func fetchReminders(for configuration: WidgetTaskListConfigurationIntent) -> [Reminder] {
        let reminderService = ReminderService()
        
        if let selectedList = configuration.selectedList {
            guard let listId = URL(string: selectedList.id)?.deletingPathExtension().lastPathComponent,
                  let url = URL(string: listId),
                  let objectId = CoreDataProvider.shared.persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url),
                  let taskList = try? CoreDataProvider.shared.persistentContainer.viewContext.existingObject(with: objectId) as? TaskList else {
                return []
            }
            return reminderService.getRemindersByList(myList: taskList)
        } else {
            let fetchRequest = reminderService.remindersByStatType(statType: mapFilterType(configuration.selectedFilter))
            do {
                return try CoreDataProvider.shared.persistentContainer.viewContext.fetch(fetchRequest)
            } catch {
                print("Failed to fetch reminders: \(error)")
                return []
            }
        }
    }
    
    private func mapFilterType(_ filterType: FilterType) -> ReminderStatType {
        switch filterType {
        case .all: return .all
        case .today: return .today
        case .scheduled: return .scheduled
        case .completed: return .completed
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: WidgetTaskListConfigurationIntent
    let reminders: [Reminder]
}

struct HexagonWidgetEntryView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack {
            Text(entry.configuration.selectedList?.name ?? entry.configuration.selectedFilter.rawValue.capitalized)
                .font(.headline)
            
            List {
                ForEach(entry.reminders.prefix(5)) { reminder in
                    WidgetReminderCellView(reminder: reminder) {
                        Task {
                            await toggleCompletion(for: reminder)
                        }
                    }
                }
            }
        }
    }
    
    func toggleCompletion(for reminder: Reminder) async {
        guard let reminderId = reminder.identifier?.uuidString else { return }
        let intent = ToggleTaskCompletionIntent(reminderId: reminderId)
        do {
            _ = try await intent.perform()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to toggle completion: \(error)")
        }
    }
}
