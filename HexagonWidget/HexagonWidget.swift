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

struct HexagonWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            contentView
        }
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
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
                Text(taskList.name ?? "Unnamed List")
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
                        Text(taskList.name ?? "Unnamed List")
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
                        Text(taskList.name ?? "Unnamed List")
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
                        Text(taskList.name ?? "Unnamed List")
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

struct HexagonWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.persistentContainer.viewContext
        
        let mockTaskList = TaskList(context: context)
        mockTaskList.listID = UUID()
        mockTaskList.name = "Home"
        
        let mockReminder1 = Reminder(context: context)
        mockReminder1.reminderID = UUID()
        mockReminder1.title = "Mock Task 1"
        mockReminder1.isCompleted = false
        
        let mockReminder2 = Reminder(context: context)
        mockReminder2.reminderID = UUID()
        mockReminder2.title = "Mock Task 2"
        mockReminder2.isCompleted = true
        
        return Group {

            HexagonWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                taskList: mockTaskList,
                reminderCount: 2,
                configuration: ConfigurationAppIntent(),
                reminders: [mockReminder1, mockReminder2]
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            HexagonWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                taskList: mockTaskList,
                reminderCount: 2,
                configuration: ConfigurationAppIntent(),
                reminders: [mockReminder1, mockReminder2]
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            HexagonWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                taskList: mockTaskList,
                reminderCount: 2,
                configuration: ConfigurationAppIntent(),
                reminders: [mockReminder1, mockReminder2]
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            
            HexagonWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                taskList: mockTaskList,
                reminderCount: 2,
                configuration: ConfigurationAppIntent(),
                reminders: [mockReminder1, mockReminder2]
            ))
            .previewContext(WidgetPreviewContext(family: .systemExtraLarge))
            
            HexagonWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                taskList: mockTaskList,
                reminderCount: 2,
                configuration: ConfigurationAppIntent(),
                reminders: [mockReminder1, mockReminder2]
            ))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            
            HexagonWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                taskList: mockTaskList,
                reminderCount: 2,
                configuration: ConfigurationAppIntent(),
                reminders: [mockReminder1, mockReminder2]
            ))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            
            HexagonWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                taskList: mockTaskList,
                reminderCount: 2,
                configuration: ConfigurationAppIntent(),
                reminders: [mockReminder1, mockReminder2]
            ))
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
        }
    }
}
