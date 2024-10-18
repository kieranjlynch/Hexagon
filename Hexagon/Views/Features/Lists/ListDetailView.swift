import SwiftUI
import HexagonData
import CoreData
import TipKi
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

    @State var dragging: Reminder?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    unassignedRemindersSection
                    subheadingsSection
                }
                .padding()
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
            }
            .task {
                await viewModel.loadContent()
            }
            .fullScreenCover(isPresented: $showSwipeableDetailView) {
                SwipeableTaskDetailViewWrapper(
                    reminders: $viewModel.reminders,
                    currentIndex: $selectedIndex
                )
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

    private var unassignedRemindersSection: some View {
        VStack(spacing: 0) {
            let unassigned = viewModel.reminders.filter { $0.subHeading == nil }
            ForEach(unassigned, id: \.self) { reminder in
                TaskCardView(
                    reminder: reminder,
                    onTap: {
                        if let index = viewModel.reminders.firstIndex(of: reminder) {
                            selectedIndex = index
                            selectedReminder = reminder
                            showSwipeableDetailView = true
                        }
                    },
                    onToggleCompletion: {
                        Task {
                            await viewModel.toggleCompletion(reminder)
                        }
                    },
                    selectedDate: Date(),
                    selectedDuration: 60.0
                )
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                .listRowSeparator(.hidden)
                .onDrag {
                    self.dragging = reminder
                    return NSItemProvider(object: reminder)
                } preview: {
                    TaskCardView(
                        reminder: reminder,
                        onTap: {
                            selectedReminder = reminder
                        },
                        onToggleCompletion: {
                            Task {
                                await viewModel.toggleCompletion(reminder)
                            }
                        },
                        selectedDate: Date(),
                        selectedDuration: 60.0
                    )
                    .frame(minWidth: 150, minHeight: 80)
                    .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .onDrop(of: [UTType.hexagonReminder], delegate: DropViewDelegate(viewModel: viewModel, item: reminder, items: $viewModel.reminders, draggedItem: $dragging, subHeading: nil))
            }
            EmptyDropView()
                .onDrop(of: [UTType.hexagonReminder], delegate: DropViewDelegate(viewModel: viewModel, item: nil, items: $viewModel.reminders, draggedItem: $dragging, subHeading: nil))
                .opacity((unassigned.count == 0) ? 1 : 0)
        }
    }

    private var subheadingsSection: some View {
        ForEach(viewModel.subHeadings, id: \.objectID) { subHeading in
            SubheadingHeader(subHeading: subHeading, viewModel: viewModel)
            let sectionItems = viewModel.reminders.filter { $0.subHeading == subHeading }
            if sectionItems.count != 0 {
                Divider()
                    .background(Color.gray.opacity(0.5))
                    .padding(.top, 4)
            }
            ForEach(sectionItems, id: \.objectID) { reminder in
                TaskCardView(
                    reminder: reminder,
                    onTap: {
                        selectedReminder = reminder
                    },
                    onToggleCompletion: {
                        Task {
                            await viewModel.toggleCompletion(reminder)
                        }
                    },
                    selectedDate: Date(),
                    selectedDuration: 60.0
                )
                .onDrag {
                    self.dragging = reminder
                    return NSItemProvider(object: reminder)
                } preview: {
                    TaskCardView(
                        reminder: reminder,
                        onTap: {
                            selectedReminder = reminder
                        },
                        onToggleCompletion: {
                            Task {
                                await viewModel.toggleCompletion(reminder)
                            }
                        },
                        selectedDate: Date(),
                        selectedDuration: 60.0
                    )
                    .frame(minWidth: 150, minHeight: 80)
                    .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                .listRowSeparator(.hidden)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                .onDrop(of: [UTType.hexagonReminder], delegate: DropViewDelegate(viewModel: viewModel, item: reminder, items: $viewModel.reminders, draggedItem: $dragging, subHeading: subHeading))

            }
            .padding(.vertical, 8)
            EmptyDropView()
                .onDrop(of: [UTType.hexagonReminder], delegate: DropViewDelegate(viewModel: viewModel, item: nil, items: $viewModel.reminders, draggedItem: $dragging, subHeading: subHeading))
                .opacity(sectionItems.count == 0 ? 1 : 0)
        }
        .sheet(item: $selectedReminder) { reminder in
            AddReminderView(reminder: reminder)
                .environmentObject(viewModel.reminderService)
                .environmentObject(viewModel.locationService)
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
}
