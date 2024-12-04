//
//  ListViewModel.swift
//  Hexagon
//

import Foundation
import SwiftUI
import CoreData
import Combine
import os

struct ListViewState: Equatable {
    var taskLists: [TaskList] = []
    var subHeadings: [SubHeading] = []
    var selectedFilter: ListFilter = .all
}

@MainActor
final class ListViewModel: NSObject, ObservableObject, @preconcurrency ErrorHandlingViewModel {
    let errorHandler: ErrorHandling = ErrorHandlerService.shared
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "ListViewModel")
    
    @Published private(set) var state: ViewState<ListViewState> = .idle
    var activeTasks = Set<Task<Void, Never>>()
    var cancellables = Set<AnyCancellable>()
    
    private let dataProvider: ListDataProvider
    private let subHeadingOperations: SubHeadingOperations
    private let reminderOperations: ReminderOperations
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TaskList>?
    private var viewState = ListViewState()
    
    init(
        context: NSManagedObjectContext,
        dataProvider: ListDataProvider,
        subHeadingOperations: SubHeadingOperations,
        reminderOperations: ReminderOperations
    ) {
        self.context = context
        self.dataProvider = dataProvider
        self.subHeadingOperations = subHeadingOperations
        self.reminderOperations = reminderOperations
        super.init()
        
        setupFetchedResultsController()
        Task {
            await loadTaskLists()
        }
    }
    
    func viewDidLoad() { }
    func viewWillAppear() { }
    func viewWillDisappear() { }
    
    func updateSelectedFilter(_ filter: ListFilter) {
        viewState.selectedFilter = filter
        Task {
            await loadTaskLists()
        }
    }
    
    func loadTaskLists() async {
        state = .loading
        
        do {
            let lists = try await dataProvider.fetchTaskLists()
            viewState.taskLists = lists
            state = .loaded(viewState)
        } catch {
            handleError(error)
            state = .error(error.localizedDescription)
        }
    }
    
    func getIncompleteRemindersCount(for taskList: TaskList) async -> Int {
        do {
            return try await context.performAsync {
                let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
                request.predicate = NSPredicate(format: "list == %@ AND isCompleted == NO", taskList)
                return try self.context.count(for: request)
            }
        } catch {
            handleError(error)
            return 0
        }
    }
    
    func fetchSubHeadings(for taskList: TaskList?) async throws {
        guard let taskList = taskList else {
            throw ValidationError.missingRequired("Task List")
        }
        
        do {
            let fetchedHeadings = try await dataProvider.fetchSubHeadings(for: taskList)
            viewState.subHeadings = fetchedHeadings
        } catch {
            throw DatabaseError.fetchFailed("Subheadings")
        }
    }
    
    func addSubHeading(title: String, to taskList: TaskList?) async {
        guard let taskList = taskList else {
            handleError(ValidationError.missingRequired("Task List"))
            return
        }
        
        do {
            try await subHeadingOperations.addSubHeading(title: title, to: taskList)
            await loadTaskLists()
        } catch {
            handleError(error)
        }
    }
    
    func updateSubHeading(_ subHeading: SubHeading) async {
        do {
            try await subHeadingOperations.updateSubHeading(subHeading)
            try await fetchSubHeadings(for: subHeading.taskList)
        } catch {
            handleError(error)
        }
    }
    
    func deleteSubHeading(_ subHeading: SubHeading) async {
        do {
            try await subHeadingOperations.deleteSubHeading(subHeading)
            if let index = viewState.subHeadings.firstIndex(of: subHeading) {
                viewState.subHeadings.remove(at: index)
                state = .loaded(viewState)
            }
        } catch {
            handleError(error)
        }
    }
    
    func moveSubHeadings(from source: IndexSet, to destination: Int, in taskList: TaskList) async {
        do {
            try await subHeadingOperations.moveSubHeadings(
                from: source,
                to: destination,
                in: taskList
            )
            await loadTaskLists()
        } catch {
            handleError(error)
        }
    }
    
    func moveReminders(from source: IndexSet, to destination: Int, in subHeading: SubHeading) async {
        do {
            try await reminderOperations.moveReminders(
                from: source,
                to: destination,
                in: subHeading
            )
            await loadTaskLists()
        } catch {
            handleError(error)
        }
    }
    
    private func setupFetchedResultsController() {
        let request: NSFetchRequest<TaskList> = TaskList.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskList.order, ascending: true)]
        request.fetchBatchSize = 20
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        fetchedResultsController?.delegate = self
        try? fetchedResultsController?.performFetch()
    }
}

extension ListViewModel: NSFetchedResultsControllerDelegate {
    nonisolated func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        Task { @MainActor in
            guard let lists = controller.fetchedObjects as? [TaskList] else { return }
            self.viewState.taskLists = lists
            self.state = .loaded(self.viewState)
        }
    }
}
