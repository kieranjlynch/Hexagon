//
//  HistoryViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 30/10/2024.
//

import SwiftUI
import CoreData
import Combine
import os


protocol ListDetailViewModelFactory {
    func createListDetailViewModel(for taskList: TaskList, parent: ListDetailViewModel?) async -> ListDetailViewModel
}

struct DefaultListDetailViewModelFactory: ListDetailViewModelFactory {
    func createListDetailViewModel(for taskList: TaskList, parent: ListDetailViewModel? = nil) async -> ListDetailViewModel {
        return await ListDetailViewModel(
            taskList: taskList,
            reminderService: ReminderFetchingService.shared,
            subHeadingService: SubheadingService.shared,
            performanceMonitor: nil,
            parentViewModel: parent
        )
    }
}

struct HistoryState: Equatable {
    var completedTasksByDate: [Date: [Reminder]] = [:]
    
    static func == (lhs: HistoryState, rhs: HistoryState) -> Bool {
        lhs.completedTasksByDate.keys == rhs.completedTasksByDate.keys
    }
}

@MainActor
final class HistoryViewModel: NSObject, ObservableObject, ViewModel {
    // MARK: - Published Properties
    @Published private(set) var viewState: ViewState<HistoryState>
    @Published var error: IdentifiableError?
    
    // MARK: - Properties
    var activeTasks = Set<Task<Void, Never>>()
    var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "HistoryViewModel")
    
    // MARK: - Dependencies
    private let tasksFetcher: any CompletedTasksFetching
    private let taskGrouper: TaskGrouping
    private let listDetailFactory: ListDetailViewModelFactory
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<Reminder>?
    private var listDetailViewModels: [UUID: ListDetailViewModel] = [:]
    private var isInitialized = false
    
    // MARK: - Initialization
    init(
        context: NSManagedObjectContext,
        tasksFetcher: any CompletedTasksFetching,
        taskGrouper: TaskGrouping,
        listDetailFactory: ListDetailViewModelFactory
    ) {
        self.context = context
        self.tasksFetcher = tasksFetcher
        self.taskGrouper = taskGrouper
        self.listDetailFactory = listDetailFactory
        self.viewState = .idle
        
        super.init()
        
        setupFetchedResultsController()
        try? fetchedResultsController?.performFetch()
    }
    
    // MARK: - Lifecycle Methods
    func viewDidLoad() {
        guard !isInitialized else { return }
        isInitialized = true
        Task {
            await performLoad()
        }
    }
    
    func viewWillAppear() { }
    
    func viewWillDisappear() { }
    
    // MARK: - Data Loading
    func performLoad() async {
        viewState = .loading
        do {
            let reminders = try await loadContent()
            await handleLoadedContent(reminders)
        } catch {
            await handleLoadError(error)
        }
    }
    
    private func loadContent() async throws -> [Reminder] {
        try await tasksFetcher.fetchCompletedTasks()
    }
    
    private func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isCompleted == %@", NSNumber(value: true)),
            NSPredicate(format: "completedAt != nil")
        ])
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.completedAt, ascending: false)]

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        fetchedResultsController?.delegate = self
        try? fetchedResultsController?.performFetch() // Ensure this is called
    }
    
    private func handleLoadedContent(_ reminders: [Reminder]) async {
        let groupedTasks = taskGrouper.groupTasksByDate(reminders)
        viewState = .loaded(HistoryState(completedTasksByDate: groupedTasks))
        await precomputeListDetailViewModels(reminders: reminders)
    }
    
    private func handleLoadError(_ error: Error) async {
        logger.error("Failed to load completed tasks: \(error.localizedDescription)")
        self.error = IdentifiableError(error: error)
        viewState = .error(error.localizedDescription)
    }
    
    // MARK: - Public Methods
    func uncompleteTask(_ reminder: Reminder) async throws {
        viewState = .loading
        
        do {
            try await tasksFetcher.uncompleteTask(reminder)
            await performLoad()
        } catch {
            logger.error("Failed to uncomplete task: \(error.localizedDescription)")
            viewState = .error(error.localizedDescription)
            throw error
        }
    }
    
    func getListDetailViewModel(for reminder: Reminder) async -> ListDetailViewModel {
        let listID = reminder.list?.listID ?? UUID()
        if let existingViewModel = listDetailViewModels[listID] {
            return existingViewModel
        }
        
        let newViewModel = await listDetailFactory.createListDetailViewModel(
            for: reminder.list ?? TaskList(),
            parent: nil
        )
        listDetailViewModels[listID] = newViewModel
        return newViewModel
    }
    
    // MARK: - Private Methods
    private func precomputeListDetailViewModels(reminders: [Reminder]) async {
        let uniqueTaskLists = Set(reminders.compactMap { $0.list })
        for taskList in uniqueTaskLists {
            let listID = taskList.listID ?? UUID()
            if listDetailViewModels[listID] == nil {
                listDetailViewModels[listID] = await listDetailFactory.createListDetailViewModel(
                    for: taskList,
                    parent: nil
                )
            }
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension HistoryViewModel: NSFetchedResultsControllerDelegate {
    nonisolated func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        Task { @MainActor [weak self] in
            await self?.performLoad()
        }
    }
}


struct DefaultTaskGrouper: TaskGrouping {
    func groupTasksByDate(_ tasks: [Reminder]) -> [Date: [Reminder]] {
        Dictionary(grouping: tasks) { reminder in
            Calendar.current.startOfDay(for: reminder.completedAt ?? Date())
        }
    }
}
