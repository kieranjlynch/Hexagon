import SwiftUI
import CoreData
import TipKit
import HexagonData

struct ListsView: View {
    @Environment(\.managedObjectContext) var context
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @EnvironmentObject private var listService: ListService
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject var reminderService: ReminderService
    @EnvironmentObject var locationService: LocationService
    @StateObject private var viewModel: ListViewModel
    @StateObject private var searchViewModel: SearchViewModel
    
    @Binding var showFloatingActionButtonTip: Bool
    @Binding var showInboxTip: Bool
    
    let floatingActionButtonTip: FloatingActionButtonTip
    let inboxTip: InboxTip
    
    @State private var showAddReminderView = false
    @State private var showAddNewListView = false
    @State private var selectedListID: NSManagedObjectID?
    @State private var showTaskSearchResults = false
    
    init(context: NSManagedObjectContext,
         reminderService: ReminderService,
         showFloatingActionButtonTip: Binding<Bool> = .constant(true),
         showInboxTip: Binding<Bool> = .constant(false),
         floatingActionButtonTip: FloatingActionButtonTip = FloatingActionButtonTip(),
         inboxTip: InboxTip = InboxTip()) {
        
        _viewModel = StateObject(wrappedValue: ListViewModel(context: context, reminderService: reminderService))
        _searchViewModel = StateObject(wrappedValue: SearchViewModel())
        
        self._showFloatingActionButtonTip = showFloatingActionButtonTip
        self._showInboxTip = showInboxTip
        
        self.floatingActionButtonTip = floatingActionButtonTip
        self.inboxTip = inboxTip
    }
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    private func deleteTaskList(_ taskList: TaskList) {
        Task {
            await viewModel.deleteTaskList(taskList)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                contentLayer
                floatingButtonLayer
                if showInboxTip {
                    inboxTipOverlay
                }
                if showTaskSearchResults {
                    taskSearchResultsOverlay
                }
            }
            .navigationTitle("Lists")
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .toolbarBackground(Color(colorScheme == .dark ? .black : .white), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            .searchable(text: $searchViewModel.searchText, prompt: "Search")
            .onChange(of: searchViewModel.searchText) { _, _ in
                Task {
                    await searchViewModel.performSearch()
                    showTaskSearchResults = !searchViewModel.searchResults.isEmpty
                }
            }
        }
        .sheet(isPresented: $showAddReminderView) {
            AddReminderView(defaultList: nil)
                .environmentObject(reminderService)
                .environmentObject(locationService)
        }
        .sheet(isPresented: $showAddNewListView) {
            AddNewListView()
        }
        .task {
            await viewModel.loadTaskLists()
            searchViewModel.setup(reminderService: reminderService, viewContext: context)
        }
    }
    
    private var contentLayer: some View {
        Group {
            if listService.taskLists.isEmpty {
                ContentUnavailableView("No Lists Available", systemImage: "list.bullet")
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.taskLists, id: \.self) { taskList in
                            ListItemView(
                                taskList: taskList,
                                selectedListID: $selectedListID,
                                onDelete: {
                                    deleteTaskList(taskList)
                                },
                                viewModel: ListDetailViewModel(
                                    context: context,
                                    taskList: taskList,
                                    reminderService: reminderService,
                                    locationService: locationService
                                )
                            )
                            .environmentObject(reminderService)
                            .environmentObject(locationService)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var floatingButtonLayer: some View {
        FloatingActionButton(
            appSettings: appSettings,
            showTip: $showFloatingActionButtonTip,
            tip: floatingActionButtonTip,
            menuItems: [.addReminder, .addNewList],
            onMenuItemSelected: { item in
                switch item {
                case .addReminder:
                    showAddReminderView = true
                case .addNewList:
                    showAddNewListView = true
                default:
                    break
                }
            }
        )
        .padding([.trailing, .bottom], 16)
    }
    
    private var inboxTipOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                TipView(inboxTip)
                    .frame(maxWidth: 250)
                    .padding()
                    .offset(x: UIHelper.inboxTipXOffset(for: dynamicTypeSize), y: UIHelper.inboxTipOffset(for: dynamicTypeSize))
                    .transition(.opacity)
            }
        }
    }
    
    private var taskSearchResultsOverlay: some View {
        VStack {
            HStack {
                Text("Task Results")
                    .font(.headline)
                Spacer()
                Button("Dismiss") {
                    showTaskSearchResults = false
                }
            }
            .padding()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(searchViewModel.searchResults, id: \.self) { reminder in
                        TaskCardView(
                            reminder: reminder,
                            viewModel: ListDetailViewModel(
                                context: context,
                                taskList: reminder.list ?? TaskList(),
                                reminderService: reminderService,
                                locationService: locationService
                            ),
                            onTap: {},
                            onToggleCompletion: {
                                Task {
                                    try await reminderService.updateReminderCompletionStatus(reminder: reminder, isCompleted: !reminder.isCompleted)
                                    await searchViewModel.performSearch()
                                }
                            },
                            selectedDate: Date(),
                            selectedDuration: 0
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding()
        .transition(.move(edge: .bottom))
    }
}
