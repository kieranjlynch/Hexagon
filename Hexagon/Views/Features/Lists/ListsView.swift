//
//  ListsView.swift
//  Hexagon
//

import SwiftUI
import CoreData
import TipKit


struct ListsView: View {
    @Environment(\.managedObjectContext) var context
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @EnvironmentObject private var listService: ListService
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject var fetchingService: ReminderFetchingServiceUI
    @EnvironmentObject var modificationService: ReminderModificationService
    @EnvironmentObject var subheadingService: SubheadingService

    @StateObject private var viewModel: ListViewModel
    @StateObject private var searchViewModel: SearchViewModel
    @StateObject private var tagService = TagService.shared

    @Binding var showFloatingActionButtonTip: Bool
    @Binding var showInboxTip: Bool

    let floatingActionButtonTip: FloatingActionButtonTip
    let inboxTip: InboxTip

    @State private var showAddReminderView = false
    @State private var showAddNewListView = false
    @State private var selectedListID: NSManagedObjectID?
    @State private var searchText = ""

    init(context: NSManagedObjectContext,
         fetchingService: ReminderFetchingServiceUI,
         modificationService: ReminderModificationService,
         subheadingService: SubheadingService,
         showFloatingActionButtonTip: Binding<Bool> = .constant(true),
         showInboxTip: Binding<Bool> = .constant(false),
         floatingActionButtonTip: FloatingActionButtonTip = FloatingActionButtonTip(),
         inboxTip: InboxTip = InboxTip()) {

        _viewModel = StateObject(wrappedValue: ListViewModel(
            context: context,
            dataProvider: fetchingService.service,
            subHeadingOperations: subheadingService,
            reminderOperations: modificationService
        ))

        _searchViewModel = StateObject(wrappedValue: SearchViewModel(
            searchDataProvider: fetchingService.service
        ))

        self._showFloatingActionButtonTip = showFloatingActionButtonTip
        self._showInboxTip = showInboxTip
        self.floatingActionButtonTip = floatingActionButtonTip
        self.inboxTip = inboxTip
    }

    private var filteredLists: [TaskList] {
        listService.taskLists.filter { taskList in
            searchText.isEmpty || (taskList.name?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                contentLayer
                floatingButtonLayer
            }
            .navigationTitle("Lists")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                            .environmentObject(appSettings)
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .toolbarBackground(Color(colorScheme == .dark ? .black : .white), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search lists")
        }
        .sheet(isPresented: $showAddReminderView) {
            AddReminderView(
                reminder: nil,
                defaultList: nil,
                persistentContainer: PersistenceController.shared.persistentContainer,
                fetchingService: fetchingService,
                modificationService: modificationService,
                tagService: tagService,
                listService: listService
            )
            .environmentObject(fetchingService)
        }
        .sheet(isPresented: $showAddNewListView) {
            AddNewListView()
        }
        .task {
            await listService.initialize()
        }
    }

    @ViewBuilder
    private var contentLayer: some View {
        if filteredLists.isEmpty {
            if searchText.isEmpty {
                ContentUnavailableView(LocalizedStringKey("No Lists Available"), systemImage: "list.bullet")
            } else {
                ContentUnavailableView.search(text: searchText)
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredLists, id: \.self) { taskList in
                        listItemView(for: taskList)
                    }
                }
                .padding()
            }
        }
    }

    private func listItemView(for taskList: TaskList) -> some View {
        ListItemView(
            taskList: taskList,
            selectedListID: $selectedListID,
            onDelete: { deleteTaskList(taskList: taskList) },
            reminderFetchingService: fetchingService.service,
            reminderModificationService: modificationService,
            subheadingService: subheadingService
        )
    }

    private func deleteTaskList(taskList: TaskList) {
        Task {
            do {
                try await viewModel.deleteTaskList(taskList)
            } catch {
                print("Failed to delete task list: \(error)")
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
}
