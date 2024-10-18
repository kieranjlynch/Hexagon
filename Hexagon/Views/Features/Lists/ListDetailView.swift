import SwiftUI
import HexagonData
import CoreData
import TipKit
import os

struct ListDetailView: View {
    @ObservedObject var viewModel: ListDetailViewModel
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject var reminderService: ReminderService
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var listService: ListService
    @State private var showingAddReminderSheet = false
    @State private var showingEditReminderSheet = false
    @State private var showingTaskScheduleView = false
    @State private var selectedReminder: Reminder?
    @State private var showFloatingActionButtonTip = true
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var searchViewModel = SearchViewModel()
    @State private var currentTokens = [ReminderToken]()
    @State private var availableTags: [ReminderTag] = []
    
    let floatingActionButtonTip = FloatingActionButtonTip()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.klynch.Hexagon", category: "ListDetailView")
    
    var body: some View {
        VStack(spacing: 0) {
            listContent
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                CustomNavigationTitle(taskList: viewModel.taskList)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            floatingActionButton
        }
        .searchable(
            text: $searchViewModel.searchText,
            tokens: $currentTokens,
            suggestedTokens: .constant(suggestedTokens),
            prompt: Text("Search")
        ) { token in
            Label(token.displayName, systemImage: token.icon)
        }
        .onAppear(perform: onAppearAction)
        .onChange(of: viewModel.reminders) { onRemindersChange($1) }
        .onChange(of: viewModel.subHeadings) { onSubHeadingsChange($1) }
        .task {
            await fetchTags()
        }
        .sheet(isPresented: $showingEditReminderSheet) {
            if let reminder = selectedReminder {
                AddReminderView(reminder: reminder, defaultList: viewModel.taskList) { updatedReminder, _, _ in
                    Task {
                        try await reminderService.updateReminder(updatedReminder)
                    }
                }
                .environmentObject(reminderService)
                .environmentObject(locationService)
                .environmentObject(listService)
            }
        }
        .sheet(isPresented: $showingTaskScheduleView) {
            if let reminder = selectedReminder {
                TaskScheduleView(task: reminder.title ?? "Untitled Task")
            }
        }
    }
    
    private var suggestedTokens: [ReminderToken] {
        var tokens: [ReminderToken] = []
        tokens += [.priority(0), .priority(1), .priority(2)]
        tokens += availableTags.map { .tag($0.tagID!, $0.name ?? "Unnamed Tag") }
        return tokens.filter { !currentTokens.contains($0) }
    }
    
    private var listContent: some View {
        List {
            ForEach(viewModel.subHeadings) { subHeading in
                sectionView(for: subHeading)
            }
            
            remindersWithoutSubheadingsSection
                .listRowSeparator(.hidden)
        }
        .listSettings()
    }
    
    private func sectionView(for subHeading: SubHeading) -> some View {
        Section(header: Text(subHeading.title ?? "Untitled")) {
            ForEach(filteredReminders(for: subHeading)) { reminder in
                reminderView(for: reminder)
                    .listRowSeparator(.hidden)
            }
        }
    }
    
    private var remindersWithoutSubheadingsSection: some View {
        Section("") {
            ForEach(filteredReminders(for: nil)) { reminder in
                reminderView(for: reminder)
            }
        }
    }
    
    private func reminderView(for reminder: Reminder) -> some View {
        TaskCardView(
            reminder: reminder,
            onTap: { logger.debug("Tapped reminder: \(reminder.title ?? "Untitled")") },
            onToggleCompletion: { toggleReminderCompletion(reminder) },
            selectedDate: Date(),
            selectedDuration: 60.0
        )
    }

    private func toggleReminderCompletion(_ reminder: Reminder) {
        Task {
            await viewModel.toggleCompletion(for: reminder)
        }
    }
    
    private var floatingActionButton: some View {
        FloatingActionButton(
            appSettings: appSettings,
            showTip: $showFloatingActionButtonTip,
            tip: floatingActionButtonTip,
            menuItems: [.edit, .delete, .schedule],
            onMenuItemSelected: { item in
                guard let reminder = viewModel.reminders.first else {
                    logger.debug("No reminder selected for action")
                    return
                }
                selectedReminder = reminder
                
                switch item {
                case .edit:
                    showingEditReminderSheet = true
                case .delete:
                    Task { await viewModel.deleteReminder(reminder) }
                case .schedule:
                    showingTaskScheduleView = true
                default:
                    break
                }
            }
        )
        .padding([.trailing, .bottom], 16)
    }
    
    private func onAppearAction() {
        logger.info("ListDetailView appeared for list: \(viewModel.taskList.name ?? "Unknown")")
        Task {
            await fetchData()
        }
        searchViewModel.setup(reminderService: reminderService, viewContext: viewModel.context)
    }
    
    private func fetchData() async {
        logger.debug("Starting to fetch reminders and subheadings")
        await viewModel.fetchReminders()
        await viewModel.fetchSubHeadings()
        await fetchTags()
        logger.debug("Finished fetching reminders and subheadings")
        logger.info("Reminders count: \(viewModel.reminders.count), Subheadings count: \(viewModel.subHeadings.count)")
        
        for reminder in viewModel.reminders {
            logger.debug("UI Reminder: id=\(reminder.reminderID?.uuidString ?? "nil"), title=\(reminder.title ?? "nil"), subHeading=\(reminder.subHeading?.title ?? "nil")")
        }
    }
    
    private func fetchTags() async {
        do {
            availableTags = try await TagService.shared.fetchTags()
        } catch {
            logger.error("Failed to fetch tags: \(error.localizedDescription)")
        }
    }
    
    private func onRemindersChange(_ newReminders: [Reminder]) {
        logger.info("Reminders updated. New count: \(newReminders.count)")
        for (index, reminder) in newReminders.enumerated() {
            logger.debug("Reminder \(index): id=\(reminder.reminderID?.uuidString ?? "nil"), title=\(reminder.title ?? "nil"), isCompleted=\(reminder.isCompleted)")
        }
    }
    
    private func onSubHeadingsChange(_ newSubHeadings: [SubHeading]) {
        logger.info("Subheadings updated. New count: \(newSubHeadings.count)")
        for (index, subHeading) in newSubHeadings.enumerated() {
            logger.debug("Subheading \(index): id=\(subHeading.subheadingID?.uuidString ?? "nil"), title=\(subHeading.title ?? "nil")")
        }
    }
    
    private func filteredReminders(for subHeading: SubHeading?) -> [Reminder] {
        let reminders = subHeading == nil ? viewModel.reminders.filter { $0.subHeading == nil } : viewModel.filteredReminders(for: subHeading!)
        
        return reminders.filter { reminder in
            var matches = true
            
            // Text search
            if !searchViewModel.searchText.isEmpty {
                let titleMatch = reminder.title?.localizedCaseInsensitiveContains(searchViewModel.searchText) ?? false
                let notesMatch = reminder.notes?.localizedCaseInsensitiveContains(searchViewModel.searchText) ?? false
                matches = titleMatch || notesMatch
            }
            
            // Token filtering
            for token in currentTokens {
                switch token {
                case .priority(let priority):
                    matches = matches && reminder.priority == priority
                case .tag(let tagID, _):
                    matches = matches && (reminder.tags?.contains(where: { ($0 as? ReminderTag)?.tagID == tagID }) ?? false)
                }
            }
            
            return matches
        }
    }
}

enum ReminderToken: Identifiable, Hashable {
    case priority(Int16)
    case tag(UUID, String)
    
    var id: String {
        switch self {
        case .priority(let value): return "priority_\(value)"
        case .tag(let id, _): return "tag_\(id)"
        }
    }
    
    var displayName: String {
        switch self {
        case .priority(let value): return "Priority \(value)"
        case .tag(_, let name): return name
        }
    }
    
    var icon: String {
        switch self {
        case .priority: return "flag"
        case .tag: return "tag"
        }
    }
}

struct CustomNavigationTitle: View {
    let taskList: TaskList
    @Environment(\.colorScheme) private var colorScheme
    
    private var isInbox: Bool {
        taskList.name == "Inbox"
    }
    
    var body: some View {
        HStack(spacing: 8) {
            listIcon
            Text(taskList.name ?? "Unnamed List")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
    }
    
    private var listIcon: some View {
        Image(systemName: isInbox ? "tray.fill" : (taskList.symbol ?? "list.bullet"))
            .foregroundColor(isInbox ? .gray : Color(UIColor.color(data: taskList.colorData ?? Data()) ?? .gray))
            .font(.system(size: 20))
    }
}
