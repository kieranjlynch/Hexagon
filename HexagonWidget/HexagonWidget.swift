import WidgetKit
import SwiftUI
import AppIntents
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
            headerView
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
        VStack(spacing: 0) {
            headerView
                .padding(.top)
            Divider()
            tasksView
            Spacer(minLength: 0)
            addButtonView
                .padding(.bottom, 16)
        }
    }
    
    var largeWidget: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.top)
            Divider()
            tasksView
            Spacer(minLength: 0)
            addButtonView
                .padding(.bottom, 16)
        }
    }
    
    var extraLargeWidget: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.top)
            Divider()
            tasksView
            Spacer(minLength: 0)
            addButtonView
                .padding(.bottom, 16)
        }
    }
    
    var headerView: some View {
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
        .padding(.horizontal)
    }
    
    var tasksView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !entry.reminders.isEmpty {
                ForEach(entry.reminders.prefix(getTaskLimit()), id: \.reminderID) { reminder in
                    HStack(spacing: 8) {
                        completionToggleButton(isCompleted: reminder.isCompleted) {
                            toggleReminderCompletion(reminder)
                        }
                        Text(reminder.title ?? "Unnamed Task")
                            .font(.body)
                            .lineLimit(1)
                            .strikethrough(reminder.isCompleted)
                        Spacer()
                    }
                }
                
                if entry.reminders.count > getTaskLimit() {
                    Text("+ \(entry.reminders.count - getTaskLimit()) more")
                        .font(.caption)
                }
            } else {
                Text("No tasks available")
                    .font(.body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    var addButtonView: some View {
        HStack {
            Spacer()
            addButton
        }
        .padding(.horizontal)
    }
    
    private var addButton: some View {
        Link(destination: URL(string: "hexagon://addTask")!) {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 30))
        }
    }
    
    private func completionToggleButton(isCompleted: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)
                .font(.system(size: 20))
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 24, height: 24)
    }
    
    private func toggleReminderCompletion(_ reminder: Reminder) {
        reminder.isCompleted.toggle()
    }
    
    private func getTaskLimit() -> Int {
        switch widgetFamily {
        case .systemSmall:
            return 1
        case .systemMedium:
            return 3
        case .systemLarge:
            return 8
        case .systemExtraLarge:
            return 12
        default:
            return 3
        }
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

//struct HexagonWidgetEntryView_Previews: PreviewProvider {
//    static var previews: some View {
//        let context = PersistenceController.shared.persistentContainer.viewContext
//        
//        let mockTaskList = TaskList(context: context)
//        mockTaskList.listID = UUID()
//        mockTaskList.name = "Home"
//        
//        let mockReminder1 = Reminder(context: context)
//        mockReminder1.reminderID = UUID()
//        mockReminder1.title = "Mock Task 1"
//        mockReminder1.isCompleted = false
//        
//        let mockReminder2 = Reminder(context: context)
//        mockReminder2.reminderID = UUID()
//        mockReminder2.title = "Mock Task 2"
//        mockReminder2.isCompleted = true
//        
//        return Group {
//            HexagonWidgetEntryView(entry: SimpleEntry(
//                date: Date(),
//                taskList: mockTaskList,
//                reminderCount: 2,
//                configuration: ConfigurationAppIntent(),
//                reminders: [mockReminder1, mockReminder2]
//            ))
//            .previewContext(WidgetPreviewContext(family: .systemSmall))
//            
//            HexagonWidgetEntryView(entry: SimpleEntry(
//                date: Date(),
//                taskList: mockTaskList,
//                reminderCount: 2,
//                configuration: ConfigurationAppIntent(),
//                reminders: [mockReminder1, mockReminder2]
//            ))
//            .previewContext(WidgetPreviewContext(family: .systemMedium))
//            
//            HexagonWidgetEntryView(entry: SimpleEntry(
//                date: Date(),
//                taskList: mockTaskList,
//                reminderCount: 2,
//                configuration: ConfigurationAppIntent(),
//                reminders: [mockReminder1, mockReminder2]
//            ))
//            .previewContext(WidgetPreviewContext(family: .systemLarge))
//            
//            HexagonWidgetEntryView(entry: SimpleEntry(
//                date: Date(),
//                taskList: mockTaskList,
//                reminderCount: 2,
//                configuration: ConfigurationAppIntent(),
//                reminders: [mockReminder1, mockReminder2]
//            ))
//            .previewContext(WidgetPreviewContext(family: .systemExtraLarge))
//            
//            HexagonWidgetEntryView(entry: SimpleEntry(
//                date: Date(),
//                taskList: mockTaskList,
//                reminderCount: 2,
//                configuration: ConfigurationAppIntent(),
//                reminders: [mockReminder1, mockReminder2]
//            ))
//            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
//            
//            HexagonWidgetEntryView(entry: SimpleEntry(
//                date: Date(),
//                taskList: mockTaskList,
//                reminderCount: 2,
//                configuration: ConfigurationAppIntent(),
//                reminders: [mockReminder1, mockReminder2]
//            ))
//            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
//            
//            HexagonWidgetEntryView(entry: SimpleEntry(
//                date: Date(),
//                taskList: mockTaskList,
//                reminderCount: 2,
//                configuration: ConfigurationAppIntent(),
//                reminders: [mockReminder1, mockReminder2]
//            ))
//            .previewContext(WidgetPreviewContext(family: .accessoryInline))
//        }
//    }
//}
