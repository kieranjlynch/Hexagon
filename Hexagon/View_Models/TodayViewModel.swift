//
//  TodayViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 03/11/2024.
//

import SwiftUI
import CoreData
import os
import Combine

struct TodayViewState: Equatable {
    var tasks: [Reminder] = []
    var lastRefreshDate: Date?
}

@MainActor
final class TodayViewModel: NSObject, ObservableObject, @preconcurrency ErrorHandlingViewModel, @preconcurrency DataLoadable {
    @Published private(set) var state: ViewState<TodayViewState> = .idle
    let errorHandler: ErrorHandling = ErrorHandlerService.shared
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "TodayViewModel")
    
    var activeTasks: Set<Task<Void, Never>> = []
    var cancellables: Set<AnyCancellable> = []
    
    private let taskService: TodayTaskServiceFacade
    private var isLoading = false
    private var isInitialized = false
    private var loadTask: Task<Void, Never>?
    
    var tasks: [Reminder] {
        if case .loaded(let viewState) = state {
            return viewState.tasks
        }
        return []
    }
    
    init(taskService: TodayTaskServiceFacade) {
        self.taskService = taskService
        super.init()
        setupObservers()
    }
    
    deinit {
        loadTask?.cancel()
        cancellables.removeAll()
    }
    
    func viewDidLoad() {
        guard !isInitialized else { return }
        isInitialized = true
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }
    
    func viewWillAppear() { }
    
    func viewWillDisappear() {
        loadTask?.cancel()
    }
    
    func performLoad() async {
        guard !isLoading else { return }
        isLoading = true
        state = .loading
        
        do {
            let reminders = try await loadContent()
            handleLoadedContent(reminders)
        } catch {
            handleError(error)
            state = .error(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func refreshTasks() async {
        guard !isLoading else { return }
        await performLoad()
    }
    
    func loadContent() async throws -> [Reminder] {
        do {
            return try await taskService.fetchTasks()
        } catch {
            throw DatabaseError.fetchFailed("Today's tasks")
        }
    }
    
    func handleLoadedContent(_ content: [Reminder]) {
        let activeTasks = content.filter { !$0.isCompleted }
        let viewState = TodayViewState(
            tasks: activeTasks,
            lastRefreshDate: Date()
        )
        self.state = .loaded(viewState)
    }
    
    func removeTask(_ task: Reminder) {
        if case .loaded(var viewState) = state {
            viewState.tasks.removeAll { $0.id == task.id }
            self.state = .loaded(viewState)
        }
    }
    
    func taskIsOverdue(_ task: Reminder) -> Bool {
        taskService.isTaskOverdue(task)
    }
    
    private func setupObservers() {
        let notificationNames: [Notification.Name] = [
            .NSManagedObjectContextDidSave,
            .reminderUpdated,
            .reminderCreated
        ]
        
        for name in notificationNames {
            NotificationCenter.default.publisher(for: name)
                .receive(on: DispatchQueue.main)
                .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main) // Reduced debounce time
                .sink { [weak self] _ in
                    Task { @MainActor [weak self] in
                        await self?.performLoad()
                    }
                }
                .store(in: &cancellables)
        }
    }
}

protocol TodayTaskServiceFacade {
    func fetchTasks() async throws -> [Reminder]
    func isTaskOverdue(_ task: Reminder) -> Bool
}

final class DefaultTodayTaskService: TodayTaskServiceFacade {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetchTasks() async throws -> [Reminder] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        let dueTodayPredicate = NSPredicate(
            format: "startDate >= %@ AND startDate < %@ AND isCompleted == %@",
            startOfDay as NSDate,
            calendar.date(byAdding: .day, value: 1, to: startOfDay)! as NSDate,
            NSNumber(value: false)
        )
        let overduePredicate = NSPredicate(
            format: "startDate < %@ AND isCompleted == %@",
            startOfDay as NSDate,
            NSNumber(value: false)
        )
        
        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            dueTodayPredicate,
            overduePredicate
        ])
        
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Reminder.startDate, ascending: true),
            NSSortDescriptor(keyPath: \Reminder.priority, ascending: false)
        ]
        
        return try await context.perform {
            try request.execute()
        }
    }
    
    func isTaskOverdue(_ task: Reminder) -> Bool {
        guard let startDate = task.startDate else { return false }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return startDate < startOfDay
    }
}

enum TodayError: LocalizedError {
    case fetchFailed
    case invalidDate
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Failed to fetch today's tasks"
        case .invalidDate:
            return "Invalid date for task"
        }
    }
}
