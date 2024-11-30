//
//  HexagonWidget.swift
//  HexWidget
//
//  Created by Kieran Lynch on 08/11/2024.
//

import WidgetKit
import SwiftUI


struct SimpleEntry: TimelineEntry {
    let date: Date
    let taskList: TaskListEntity?
    let reminderCount: Int
    let configuration: ConfigurationAppIntent
    let reminders: [Reminder]
    let error: Error?
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            taskList: nil,
            reminderCount: 0,
            configuration: ConfigurationAppIntent(),
            reminders: [],
            error: nil
        )
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        await getEntry(for: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = await getEntry(for: configuration)
        let nextUpdate = calculateNextUpdateTime(from: entry.reminders)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func calculateNextUpdateTime(from reminders: [Reminder]) -> Date {
        let nextDueDate = reminders
            .compactMap { $0.reminderTime }
            .filter { $0 > Date() }
            .min() ?? Date().addingTimeInterval(1800)
        
        let minUpdateInterval: TimeInterval = 300
        let targetDate = max(nextDueDate, Date().addingTimeInterval(minUpdateInterval))
        
        return targetDate
    }
    
    enum WidgetError: LocalizedError {
        case dataFetchFailed
        case listNotFound
        case invalidConfiguration
        case networkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .dataFetchFailed:
                return "Unable to fetch data"
            case .listNotFound:
                return "List not found"
            case .invalidConfiguration:
                return "Invalid configuration"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }
    
    @MainActor
    private func getEntry(for configuration: ConfigurationAppIntent) async -> SimpleEntry {
        do {
            try await PersistenceController.shared.initialize()
            await ListService.shared.initialize()
            await TaskListQuery.updateCache()
            
            let reminderProvider = WidgetReminderProvider(
                reminderFetchingService: ReminderFetchingService.shared
            )
            
            guard let taskListEntity = configuration.taskList else {
                throw WidgetError.invalidConfiguration
            }
            
            let taskList = try await ListService.shared.fetchOne(id: taskListEntity.id)
            guard let taskList = taskList else {
                throw WidgetError.listNotFound
            }
            
            let reminders = try await reminderProvider.getRemindersForList(taskList)
            
            return SimpleEntry(
                date: Date(),
                taskList: configuration.taskList,
                reminderCount: reminders.count,
                configuration: configuration,
                reminders: reminders,
                error: nil
            )
        } catch {
            return SimpleEntry(
                date: Date(),
                taskList: nil,
                reminderCount: 0,
                configuration: configuration,
                reminders: [],
                error: error
            )
        }
    }
}

struct HexagonWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            if let error = entry.error {
                errorView(error)
            } else {
                contentView
            }
        }
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
        .privacySensitive()
    }
    
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
            Text(error.localizedDescription)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    @ViewBuilder
    var contentView: some View {
        switch widgetFamily {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .systemLarge:
            largeWidget
        case .systemExtraLarge:
            extraLargeWidget
        case .accessoryCircular:
            circularAccessoryWidget
        case .accessoryRectangular:
            rectangularAccessoryWidget
        case .accessoryInline:
            inlineAccessoryWidget
        @unknown default:
            smallWidget
        }
    }
    
    var smallWidget: some View {
        VStack {
            if let taskList = entry.taskList {
                Text(taskList.name)
                    .font(.subheadline)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("No list selected")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            Text("\(entry.reminderCount)")
                .font(.system(size: 50))
                .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()
            
            Text("tasks")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
    }
    
    var mediumWidget: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if let taskList = entry.taskList {
                        Text(taskList.name)
                            .font(.headline)
                        Spacer()
                        Text("\(entry.reminderCount) tasks")
                            .font(.subheadline)
                    } else {
                        Text("No list selected")
                            .font(.headline)
                    }
                }
                
                if !entry.reminders.isEmpty {
                    ForEach(entry.reminders.prefix(3), id: \.reminderID) { reminder in
                        HStack {
                            completionToggleButton(isCompleted: reminder.isCompleted) {
                                toggleReminderCompletion(reminder)
                            }
                            Text(reminder.title ?? "Unnamed Task")
                                .font(.body)
                                .lineLimit(1)
                                .strikethrough(reminder.isCompleted)
                        }
                    }
                } else {
                    Text("No tasks available")
                        .font(.body)
                }
            }
            .padding()
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    addButton
                }
                .padding()
            }
        }
    }
    
    var largeWidget: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if let taskList = entry.taskList {
                        Text(taskList.name)
                            .font(.headline)
                        Spacer()
                        Text("\(entry.reminderCount) tasks")
                            .font(.subheadline)
                    } else {
                        Text("No list selected")
                            .font(.headline)
                    }
                }
                
                Divider()
                
                if !entry.reminders.isEmpty {
                    ForEach(entry.reminders.prefix(8), id: \.reminderID) { reminder in
                        HStack {
                            completionToggleButton(isCompleted: reminder.isCompleted) {
                                toggleReminderCompletion(reminder)
                            }
                            Text(reminder.title ?? "Unnamed Task")
                                .font(.body)
                                .lineLimit(1)
                                .strikethrough(reminder.isCompleted)
                        }
                    }
                    
                    if entry.reminders.count > 8 {
                        Text("+ \(entry.reminders.count - 8) more")
                            .font(.caption)
                    }
                } else {
                    Text("No tasks available")
                        .font(.body)
                }
            }
            .padding()
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    addButton
                }
                .padding()
            }
        }
    }
    
    var extraLargeWidget: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if let taskList = entry.taskList {
                        Text(taskList.name)
                            .font(.title)
                        Spacer()
                        Text("\(entry.reminderCount) tasks")
                            .font(.headline)
                    } else {
                        Text("No list selected")
                            .font(.title)
                    }
                }
                
                Divider()
                
                if !entry.reminders.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(entry.reminders.prefix(8), id: \.reminderID) { reminder in
                            HStack {
                                completionToggleButton(isCompleted: reminder.isCompleted) {
                                    toggleReminderCompletion(reminder)
                                }
                                Text(reminder.title ?? "Unnamed Task")
                                    .font(.body)
                                    .lineLimit(1)
                                    .strikethrough(reminder.isCompleted)
                            }
                        }
                    }
                    
                    if entry.reminders.count > 8 {
                        Text("+ \(entry.reminders.count - 8) more")
                            .font(.caption)
                    }
                } else {
                    Text("No tasks available")
                        .font(.body)
                }
            }
            .padding()
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    addButton
                }
                .padding()
            }
        }
    }
    
    private var addButton: some View {
        Button(action: {
            // Add task action
        }) {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 30))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func completionToggleButton(isCompleted: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)
                .font(.system(size: 20))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func toggleReminderCompletion(_ reminder: Reminder) {
        reminder.isCompleted.toggle()
    }
    
    var circularAccessoryWidget: some View {
        VStack {
            if let taskList = entry.taskList {
                Text("\(entry.reminderCount)")
                    .font(.system(size: 32, weight: .bold))
                Text(taskList.name)
                    .font(.system(size: 12))
                    .lineLimit(1)
            } else {
                Text("No List")
                    .font(.system(size: 12))
            }
        }
    }
    
    var rectangularAccessoryWidget: some View {
        HStack {
            if let taskList = entry.taskList {
                VStack(alignment: .leading) {
                    Text(taskList.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text("\(entry.reminderCount) tasks")
                        .font(.subheadline)
                }
            } else {
                Text("No List Selected")
                    .font(.headline)
            }
        }
    }
    
    var inlineAccessoryWidget: some View {
        if let taskList = entry.taskList {
            Text("\(taskList.name): \(entry.reminderCount)")
        } else {
            Text("No List")
        }
    }
}

struct HexagonWidget: Widget {
    let kind: String = "HexagonWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            HexagonWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Task List Widget")
        .description("Display your tasks from a selected list.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .systemExtraLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}
