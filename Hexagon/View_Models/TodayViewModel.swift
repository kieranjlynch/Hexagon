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
final class TodayViewModel: ObservableObject {
    @Published private(set) var viewState = ViewState<TodayViewState>.idle
    @Published var error: IdentifiableError?

    var activeTasks: Set<Task<Void, Never>> = []
    var cancellables: Set<AnyCancellable> = []

    private let taskService: TodayTaskServiceFacade
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "TodayViewModel")
    private var isLoading = false
    private var isInitialized = false
    private var loadTask: Task<Void, Never>?

    var tasks: [Reminder] {
        if case .loaded(let state) = viewState {
            return state.tasks
        }
        return []
    }

    init(taskService: TodayTaskServiceFacade) {
        self.taskService = taskService
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
        
        viewState = .loading
        do {
            let reminders = try await loadContent()
            handleLoadedContent(reminders)
        } catch {
            handleLoadError(error)
        }
        
        isLoading = false
    }
    
    func refreshTasks() async {
        guard !isLoading else { return }
        await performLoad()
    }

    func taskIsOverdue(_ task: Reminder) -> Bool {
        taskService.isTaskOverdue(task)
    }

    private func setupObservers() {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.performLoad()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .reminderUpdated)
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.performLoad()
                }
            }
            .store(in: &cancellables)
    }
}

extension TodayViewModel: DataLoadable {
    typealias LoadedData = [Reminder]
    
    func loadContent() async throws -> [Reminder] {
        try await taskService.fetchTasks()
    }
    
    nonisolated func handleLoadedContent(_ tasks: [Reminder]) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let state = TodayViewState(tasks: tasks)
            self.viewState = .loaded(state)
        }
    }
    
    nonisolated func handleLoadError(_ error: Error) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.logger.error("Failed to load tasks: \(error.localizedDescription)")
            self.error = IdentifiableError(error: error)
            self.viewState = .error(error.localizedDescription)
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

// MARK: - Error Types
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
