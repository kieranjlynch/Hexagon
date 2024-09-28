//
//  HexagonWidget.swift
//  HexagonWidget
//
//  Created by Kieran Lynch on 27/09/2024.
//

import WidgetKit
import SwiftUI
import os
import HexagonData
import CoreData

struct HexagonWidget: Widget {
    let kind: String = "HexagonWidget"
    
    init() {
        print("Widget: HexagonWidget initialized")
    }

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            HexagonWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Hexagon Tasks")
        .description("Display your tasks from Hexagon.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
    }
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), tasks: [])
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, tasks: loadTasks(for: configuration.selectedList))
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(date: Date(), configuration: configuration, tasks: loadTasks(for: configuration.selectedList))
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
    }

    private func loadTasks(for selectedList: ListEntity?) -> [ReminderTask] {
        let userDefaults = UserDefaults(suiteName: "group.com.yourcompany.Hexagon")
        let tasksData = userDefaults?.data(forKey: "WidgetTasks")
        let tasks = (try? JSONDecoder().decode([ReminderTask].self, from: tasksData ?? Data())) ?? []
        return tasks.filter { $0.listID == selectedList?.id }
    }
}

struct ReminderTask: Identifiable, Codable {
    let id: String
    let title: String
    let isCompleted: Bool
    let listID: UUID
}

//struct Provider: AppIntentTimelineProvider {
//    init() {
//        print("Widget: Provider initialized")
//    }
//    func placeholder(in context: Context) -> SimpleEntry {
//        print("Widget: placeholder called")
//        return SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), tasks: [])
//    }
//
//    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
//        print("Widget: snapshot called for list: \(configuration.selectedList?.name ?? "nil")")
//        return await getEntry(for: configuration)
//    }
//
//    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
//        print("Widget: timeline called for list: \(configuration.selectedList?.name ?? "nil")")
//        let entry = await getEntry(for: configuration)
//        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
//        return Timeline(entries: [entry], policy: .after(nextUpdateDate))
//    }
//
//    private func getEntry(for configuration: ConfigurationAppIntent) async -> SimpleEntry {
//        print("Widget: getEntry called for list: \(configuration.selectedList?.name ?? "nil")")
//        do {
//            try await PersistenceController.shared.initialize()
//            print("Widget: PersistenceController initialized")
//            let tasks = await fetchTasks(for: configuration.selectedList)
//            print("Widget: Fetched \(tasks.count) tasks")
//            return SimpleEntry(date: Date(), configuration: configuration, tasks: tasks)
//        } catch {
//            print("Widget: Error in getEntry: \(error.localizedDescription)")
//            return SimpleEntry(date: Date(), configuration: configuration, tasks: [])
//        }
//    }
//
//    private func fetchTasks(for selectedList: ListEntity?) async -> [ReminderTask] {
//        print("Widget: fetchTasks called for list: \(selectedList?.name ?? "nil")")
//        let context = PersistenceController.shared.persistentContainer.viewContext
//        let fetchRequest: NSFetchRequest<HexagonData.Reminder> = HexagonData.Reminder.fetchRequest()
//        
//        if let listID = selectedList?.id {
//            fetchRequest.predicate = NSPredicate(format: "list.listID == %@ AND isCompleted == NO", listID as CVarArg)
//            print("Widget: Fetching tasks for list ID: \(listID)")
//        } else {
//            fetchRequest.predicate = NSPredicate(format: "list == nil AND isCompleted == NO")
//            print("Widget: Fetching unassigned tasks")
//        }
//        
//        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \HexagonData.Reminder.startDate, ascending: true)]
//        fetchRequest.fetchLimit = 5
//        
//        print("Widget: Fetch request: \(fetchRequest)")
//        
//        do {
//            let reminders = try context.fetch(fetchRequest)
//            print("Widget: Fetched \(reminders.count) reminders")
//            return reminders.map { reminder in
//                print("Widget: Task: \(reminder.title ?? "Untitled"), ID: \(reminder.reminderID?.uuidString ?? "Unknown"), List: \(reminder.list?.name ?? "No List")")
//                return ReminderTask(id: reminder.reminderID?.uuidString ?? UUID().uuidString, title: reminder.title ?? "", isCompleted: reminder.isCompleted)
//            }
//        } catch {
//            print("Widget: Error fetching tasks: \(error.localizedDescription)")
//            return []
//        }
//    }
//}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let tasks: [ReminderTask]

    init(date: Date, configuration: ConfigurationAppIntent, tasks: [ReminderTask]) {
        self.date = date
        self.configuration = configuration
        self.tasks = tasks
        print("Widget: SimpleEntry created with \(tasks.count) tasks")
    }
}

struct HexagonWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) var renderingMode
    
    init(entry: Provider.Entry) {
        self.entry = entry
        print("Widget: HexagonWidgetEntryView initialized with \(entry.tasks.count) tasks")
    }
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        case .systemLarge, .systemExtraLarge:
            largeToExtraLargeWidgetView
        case .accessoryRectangular:
            accessoryRectangularWidgetView
        case .accessoryCircular, .accessoryInline:
            Text("Unsupported")
        @unknown default:
            Text("Unknown widget family")
        }
    }
    
    private var smallWidgetView: some View {
        VStack {
            Text(entry.configuration.selectedList?.name ?? "Inbox")
                .font(.headline)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.top, .leading, .trailing], 8)
            
            Spacer()
            
            Text("\(entry.tasks.count)")
                .font(.system(size: 60, weight: .bold, design: .default))
                .foregroundColor(.primary)
                .animation(.spring(), value: entry.tasks.count)
            
            Text("tasks")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private var mediumWidgetView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.configuration.selectedList?.name ?? "Inbox")
                .font(.headline)
                .padding([.top, .leading, .trailing], 8)
            
            Divider()
            
            ForEach(entry.tasks) { task in
                HStack {
                    Button(intent: HexagonData.ToggleTaskCompletionIntent(taskID: task.id)) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.isCompleted ? .green : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(task.isCompleted ? "Mark as incomplete" : "Mark as complete")
                    
                    Text(task.title)
                        .strikethrough(task.isCompleted, color: .gray)
                        .foregroundColor(task.isCompleted ? .gray : .primary)
                        .lineLimit(1)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                .animation(.spring(), value: task.isCompleted)
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private var largeToExtraLargeWidgetView: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.configuration.selectedList?.name ?? "Inbox")
                    .font(.headline)
                    .padding([.top, .leading, .trailing], 8)
                
                Divider()
                
                ForEach(entry.tasks) { task in
                    HStack {
                        Button(intent: HexagonData.ToggleTaskCompletionIntent(taskID: task.id)) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : .gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel(task.isCompleted ? "Mark as incomplete" : "Mark as complete")
                        
                        Text(task.title)
                            .strikethrough(task.isCompleted, color: .gray)
                            .foregroundColor(task.isCompleted ? .gray : .primary)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .animation(.spring(), value: task.isCompleted)
                }
                
                Spacer()
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Link(destination: URL(string: "hexagon://addTask")!) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.blue)
                            .shadow(radius: 2)
                    }
                    .accessibilityLabel("Add Task")
                    .accessibilityHint("Tap to add a new task")
                    .padding([.trailing, .bottom], 8)
                }
            }
        }
    }
    
    private var accessoryRectangularWidgetView: some View {
        VStack(alignment: .leading) {
            Text(entry.configuration.selectedList?.name ?? "Inbox")
                .font(.headline)
                .padding([.top, .leading, .trailing], 8)
            
            Divider()
            
            ForEach(entry.tasks) { task in
                HStack {
                    Text(task.title)
                        .strikethrough(task.isCompleted, color: .gray)
                        .foregroundColor(task.isCompleted ? .gray : .primary)
                        .lineLimit(1)
                    
                    Spacer()
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
