import SwiftUI
import CoreData


struct TodayView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var fetchingService: ReminderFetchingServiceUI
    @EnvironmentObject private var modificationService: ReminderModificationService
    @EnvironmentObject private var subheadingService: SubheadingService
    @EnvironmentObject private var tagService: TagService
    @EnvironmentObject private var listService: ListService
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: TodayViewModel
    @State private var listViewModels: [UUID: ListDetailViewModel] = [:]
    
    init() {
        let taskService = DefaultTodayTaskService(context: PersistenceController.shared.persistentContainer.viewContext)
        _viewModel = StateObject(wrappedValue: TodayViewModel(taskService: taskService))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.tasks.isEmpty {
                    ContentUnavailableView("No Tasks Due Today", systemImage: "calendar.badge.checkmark")
                } else {
                    taskListView
                }
            }
            .navigationTitle("Today")
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
            .onAppear {
                viewModel.viewDidLoad()
            }
            .refreshable {
                await viewModel.refreshTasks()
            }
        }
    }
    
    private var taskListView: some View {
        List {
            ForEach(Array(viewModel.tasks.enumerated()), id: \.element.id) { index, task in
                createTaskRow(for: task, at: index)
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private func createTaskRow(for task: Reminder, at index: Int) -> some View {
        let detailViewModel = getOrCreateListDetailViewModel(for: task)
        
        return ReminderRow(
            reminder: task,
            taskList: task.list ?? TaskList(),
            viewModel: detailViewModel,
            index: index
        )
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .listRowBackground(Color.clear)
        .overlay(alignment: .topTrailing) {
            if viewModel.taskIsOverdue(task) {
                Text("OVERDUE")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(4)
                    .padding(8)
            }
        }
    }
    
    private func getOrCreateListDetailViewModel(for task: Reminder) -> ListDetailViewModel {
        guard let listID = task.list?.listID else {
            return ListDetailViewModel(
                taskList: task.list ?? TaskList(),
                reminderService: fetchingService.service,
                subHeadingService: subheadingService,
                performanceMonitor: nil
            )
        }
        
        if let existingViewModel = listViewModels[listID] {
            return existingViewModel
        }
        
        let newViewModel = ListDetailViewModel(
            taskList: task.list ?? TaskList(),
            reminderService: fetchingService.service,
            subHeadingService: subheadingService,
            performanceMonitor: nil
        )
        
        listViewModels[listID] = newViewModel
        return newViewModel
    }
}
