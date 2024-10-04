//
//  HexagonWidget.swift
//  HexagonWidget
//
//  Created by Kieran Lynch on 04/10/2024.
//

import WidgetKit
import SwiftUI
import HexagonData

struct Provider: AppIntentTimelineProvider {
    typealias Intent = ConfigurationAppIntent
    typealias Entry = SimpleEntry
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), taskList: nil, reminderCount: 0, configuration: ConfigurationAppIntent(), reminders: [])
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        await getEntry(for: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = await getEntry(for: configuration)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
    }
    
    private func getEntry(for configuration: ConfigurationAppIntent) async -> SimpleEntry {
        guard let taskListEntity = configuration.taskList else {
            return SimpleEntry(date: Date(), taskList: nil, reminderCount: 0, configuration: configuration, reminders: [])
        }
        
        let taskListID = taskListEntity.id
        
        do {
            let taskLists = try await ListService.shared.updateTaskLists()
            guard let taskList = taskLists.first(where: { $0.listID == taskListID }) else {
                return SimpleEntry(date: Date(), taskList: nil, reminderCount: 0, configuration: configuration, reminders: [])
            }
            
            let reminders = try await ReminderService.shared.getRemindersForList(taskList)
            let incompleteReminders = reminders.filter { !$0.isCompleted }
            
            return SimpleEntry(
                date: Date(),
                taskList: taskList,
                reminderCount: incompleteReminders.count,
                configuration: configuration,
                reminders: reminders
            )
        } catch {
            print("Error fetching data for widget: \(error)")
            return SimpleEntry(date: Date(), taskList: nil, reminderCount: 0, configuration: configuration, reminders: [])
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let taskList: TaskList?
    let reminderCount: Int
    let configuration: ConfigurationAppIntent
    let reminders: [Reminder]
}

struct HexagonWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry
    
    var body: some View {
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
        VStack(alignment: .leading, spacing: 4) {
            if let taskList = entry.taskList {
                Text(taskList.name ?? "Unnamed List")
                    .font(.headline)
                    .lineLimit(1)
                Text("\(entry.reminderCount) tasks")
                    .font(.subheadline)
            } else {
                Text("No list selected")
                    .font(.headline)
            }
        }
        .padding()
    }
    
    var mediumWidget: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let taskList = entry.taskList {
                    Text(taskList.name ?? "Unnamed List")
                        .font(.headline)
                    Text("\(entry.reminderCount) incomplete tasks")
                        .font(.subheadline)
                    Text("Last updated: \(entry.date, style: .time)")
                        .font(.caption)
                } else {
                    Text("No list selected")
                        .font(.headline)
                }
            }
            Spacer()
            CircularProgressView(progress: Double(entry.reminderCount) / Double(max(entry.reminders.count, 1)))
        }
        .padding()
    }
    
    var largeWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let taskList = entry.taskList {
                Text(taskList.name ?? "Unnamed List")
                    .font(.headline)
                Text("\(entry.reminderCount) incomplete tasks")
                    .font(.subheadline)
                Divider()
                ForEach(entry.reminders.prefix(5), id: \.reminderID) { reminder in
                    HStack {
                        Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                        Text(reminder.title ?? "Untitled")
                            .lineLimit(1)
                    }
                }
                if entry.reminders.count > 5 {
                    Text("+ \(entry.reminders.count - 5) more")
                        .font(.caption)
                }
            } else {
                Text("No list selected")
                    .font(.headline)
            }
        }
        .padding()
    }
    
    var extraLargeWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let taskList = entry.taskList {
                HStack {
                    VStack(alignment: .leading) {
                        Text(taskList.name ?? "Unnamed List")
                            .font(.title)
                        Text("\(entry.reminderCount) incomplete tasks")
                            .font(.headline)
                    }
                    Spacer()
                    CircularProgressView(progress: Double(entry.reminderCount) / Double(max(entry.reminders.count, 1)))
                }
                Divider()
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(entry.reminders.prefix(10), id: \.reminderID) { reminder in
                        HStack {
                            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                            Text(reminder.title ?? "Untitled")
                                .lineLimit(1)
                        }
                    }
                }
                if entry.reminders.count > 10 {
                    Text("+ \(entry.reminders.count - 10) more")
                        .font(.caption)
                }
            } else {
                Text("No list selected")
                    .font(.title)
            }
        }
        .padding()
    }
    
    var circularAccessoryWidget: some View {
        VStack {
            if let taskList = entry.taskList {
                Text("\(entry.reminderCount)")
                    .font(.system(size: 32, weight: .bold))
                Text(taskList.name ?? "Tasks")
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
                    Text(taskList.name ?? "Tasks")
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
            Text("\(taskList.name ?? "Tasks"): \(entry.reminderCount)")
        } else {
            Text("No List")
        }
    }
}

struct CircularProgressView: View {
    var progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 8.0)
                .opacity(0.3)
                .foregroundColor(Color.blue)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 8.0, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color.blue)
                .rotationEffect(Angle(degrees: 270.0))
            
            Text(String(format: "%.0f%%", min(self.progress, 1.0)*100.0))
                .font(.caption)
                .bold()
        }
    }
}

struct HexagonWidget: Widget {
    let kind: String = "HexagonWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            HexagonWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
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
    }
}
