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
final class ListViewModel: NSObject, ViewModel, ViewStateManaging, ErrorHandling, TaskManaging, LoggerProvider, ObservableObject {
    typealias State = ListViewState
    
    @Published private(set) var viewState: ListViewState
    @Published var state: ViewState<ListViewState> = .idle
    @Published var error: IdentifiableError?
    
    var activeTasks = Set<Task<Void, Never>>()
    var cancellables = Set<AnyCancellable>()
    
    let logger: Logger
    
    private let dataProvider: ListDataProvider
    private let subHeadingOperations: SubHeadingOperations
    private let reminderOperations: ReminderOperations
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TaskList>?
    
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
        self.viewState = ListViewState()
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "ListViewModel")
        
        super.init()
        
        setupFetchedResultsController()
        Task {
            await loadTaskLists()
        }
    }
    
    func viewDidLoad() {
        // Implement if needed
    }
    
    func viewWillAppear() {
        // Implement if needed
    }
    
    func viewWillDisappear() {
        // Implement if needed
    }
    
    func updateSelectedFilter(_ filter: ListFilter) {
        viewState.selectedFilter = filter
        Task {
            await loadTaskLists()
        }
    }
    
    func updateViewState(_ newState: ViewState<ListViewState>) {
        state = newState
        if case .error(let message) = newState {
            error = IdentifiableError(message: message)
        }
    }
    
    func handleError(_ error: Error) {
        self.error = IdentifiableError(error: error)
    }
    
    func getIncompleteRemindersCount(for taskList: TaskList) async -> Int {
        await dataProvider.getIncompleteRemindersCount(for: taskList)
    }
    
    func loadTaskLists() async {
        updateViewState(.loading)
        
        do {
            let lists = try await dataProvider.fetchTaskLists()
            viewState.taskLists = lists
            updateViewState(.loaded(viewState))
        } catch {
            updateViewState(.error(error.localizedDescription))
            handleError(error)
            logger.error("Failed to load task lists: \(error.localizedDescription)")
        }
    }
    
    func fetchSubHeadings(for taskList: TaskList?) async throws {
        guard let taskList = taskList else { return }
        
        do {
            let fetchedHeadings = try await dataProvider.fetchSubHeadings(for: taskList)
            viewState.subHeadings = fetchedHeadings
        } catch {
            logger.error("Failed to fetch subheadings: \(error.localizedDescription)")
            throw error
        }
    }
    
    func addSubHeading(title: String, to taskList: TaskList?) async {
        guard let taskList = taskList else { return }
        
        do {
            try await subHeadingOperations.addSubHeading(title: title, to: taskList)
            await loadTaskLists()
        } catch {
            logger.error("Failed to add subheading: \(error.localizedDescription)")
            handleError(error)
        }
    }
    
    func updateSubHeading(_ subHeading: SubHeading) async {
        do {
            try await subHeadingOperations.updateSubHeading(subHeading)
            try await fetchSubHeadings(for: subHeading.taskList)
        } catch {
            logger.error("Failed to update subheading: \(error.localizedDescription)")
            handleError(error)
        }
    }
    
    func deleteSubHeading(_ subHeading: SubHeading) async {
        do {
            try await subHeadingOperations.deleteSubHeading(subHeading)
            if let index = viewState.subHeadings.firstIndex(of: subHeading) {
                viewState.subHeadings.remove(at: index)
            }
        } catch {
            logger.error("Failed to delete subheading: \(error.localizedDescription)")
            handleError(error)
        }
    }
    
    func moveSubHeadings(from source: IndexSet, to destination: Int) async {
        guard let taskList = viewState.subHeadings.first?.taskList else { return }
        
        do {
            try await subHeadingOperations.moveSubHeadings(
                from: source,
                to: destination,
                in: taskList
            )
            await loadTaskLists()
        } catch {
            logger.error("Failed to move subheadings: \(error.localizedDescription)")
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
            logger.error("Failed to move reminders: \(error.localizedDescription)")
            handleError(error)
        }
    }
    
    func deleteTaskList(_ taskList: TaskList) async throws {
        updateViewState(.loading)
        
        do {
            try await dataProvider.deleteTaskList(taskList)
            if let index = viewState.taskLists.firstIndex(where: { $0.objectID == taskList.objectID }) {
                viewState.taskLists.remove(at: index)
            }
            updateViewState(.loaded(viewState))
        } catch {
            updateViewState(.error(error.localizedDescription))
            logger.error("Failed to delete task list: \(error.localizedDescription)")
            throw error
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
            viewState.taskLists = lists
        }
    }
}
