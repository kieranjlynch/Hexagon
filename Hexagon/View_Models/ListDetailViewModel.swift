//
//  ListDetailViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 17/09/2024.

import SwiftUI
import CoreData
import os
import Combine

struct ListDetailViewState: Equatable {
    var reminders: [Reminder] = []
    var subHeadings: [SubHeading] = []
    var listSymbol: String = ""
}

@MainActor
final class ListDetailViewModel: NSObject, ViewModel, @preconcurrency ViewStateManaging, @preconcurrency ErrorHandlingViewModel, TaskManaging, LoggerProvider {
    typealias State = ListDetailViewState
    
    let errorHandler: ErrorHandling = ErrorHandlerService.shared
    
    @Published private(set) var viewState: ListDetailViewState
    @Published private(set) var internalState: ViewState<ListDetailViewState> = .idle
    @Published var error: IdentifiableError?
    var state: ViewState<ListDetailViewState> {
        internalState
    }
    var reminders: [Reminder] {
        viewState.reminders
    }
    var activeTasks = Set<Task<Void, Never>>()
    var cancellables = Set<AnyCancellable>()
    
    let logger: Logger
    let taskList: TaskList
    
    private let reminderService: ReminderServiceFacade
    private let subHeadingService: SubHeadingServiceFacade
    private let performanceMonitor: PerformanceMonitoring?
    private weak var parentViewModel: ListDetailViewModel?
    
    private var isSearchSetupComplete = false
    private var isLoadingContent = false
    private var isInitialized = false
    private var cleanupTask: Task<Void, Never>?
    
    init(
        taskList: TaskList,
        reminderService: ReminderServiceFacade,
        subHeadingService: SubHeadingServiceFacade,
        performanceMonitor: PerformanceMonitoring? = nil,
        parentViewModel: ListDetailViewModel? = nil
    ) {
        self.taskList = taskList
        self.reminderService = reminderService
        self.subHeadingService = subHeadingService
        self.performanceMonitor = performanceMonitor
        self.parentViewModel = parentViewModel
        self.viewState = ListDetailViewState()
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "ListDetailViewModel")
        
        super.init()
        
        if parentViewModel == nil {
            setupObservers()
            Task {
                await loadInitialState()
            }
        }
    }
    
    deinit {
        activeTasks.forEach { $0.cancel() }
        activeTasks.removeAll()
        cancellables.removeAll()
    }
    
    private func setupObservers() {
        let notificationNames: [Notification.Name] = [
            .NSManagedObjectContextDidSave,
            .reminderUpdated,
            .reminderCreated,
            .NSManagedObjectContextObjectsDidChange
        ]
        
        for name in notificationNames {
            NotificationCenter.default.publisher(for: name)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    Task { @MainActor [weak self] in
                        await self?.reloadRemindersState()
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    private func loadInitialState() async {
        guard !isInitialized else { return }
        isInitialized = true
        
        do {
            async let reminders = loadContent()
            async let subHeadings = subHeadingService.fetchSubHeadings(for: self.taskList)
            
            let (loadedReminders, loadedSubHeadings) = try await (reminders, subHeadings)
            viewState.reminders = loadedReminders
            viewState.subHeadings = loadedSubHeadings
            await updateViewState(.loaded(viewState))
            logger.debug("Initial state loaded with \(loadedReminders.count) reminders and \(loadedSubHeadings.count) subheadings")
        } catch {
            logger.error("Failed to load initial state: \(error.localizedDescription)")
            await updateViewState(.error(error.localizedDescription))
            handleError(error)
        }
    }
    
    func loadContent() async throws -> [Reminder] {
        guard !isLoadingContent else { return [] }
        isLoadingContent = true
        defer { isLoadingContent = false }
        
        do {
            logger.debug("Fetching reminders for task list: \(self.taskList.name ?? "unnamed")")
            let fetchedReminders = try await reminderService.fetchReminders(for: taskList, isCompleted: false)
            logger.debug("Fetched \(fetchedReminders.count) reminders")
            return fetchedReminders
        } catch {
            logger.error("Failed to load reminders: \(error.localizedDescription)")
            throw error
        }
    }
    
    var subHeadingsArray: [SubHeading] {
        if let parent = parentViewModel {
            return parent.subHeadingsArray
        }
        return viewState.subHeadings.sorted { ($0.order, $0.title ?? "") < ($1.order, $1.title ?? "") }
    }
    
    func sortReminders(by sortType: ReminderSortType) async {
        do {
            let reminders = try await reminderService.fetchSortedReminders(for: taskList, sortType: sortType)
            viewState.reminders = reminders
            await updateViewState(.loaded(viewState))
        } catch {
            handleError(error)
            await updateViewState(.error(error.localizedDescription))
        }
    }
    
    func toggleCompletion(_ reminder: Reminder) async {
        do {
            let updatedReminder = try await reminderService.toggleCompletion(reminder)
            if let index = viewState.reminders.firstIndex(of: reminder) {
                if updatedReminder.isCompleted {
                    viewState.reminders.remove(at: index)
                } else {
                    viewState.reminders[index] = updatedReminder
                }
            }
            NotificationCenter.default.post(name: .reminderUpdated, object: nil)
        } catch {
            handleError(error)
        }
    }
    
    func setupSearchViewModel(_ searchViewModel: SearchViewModel) {
        guard !isSearchSetupComplete else { return }
        isSearchSetupComplete = true
        
        Task { @MainActor in
            let predicate = NSPredicate(format: "list == %@ AND isCompleted == NO", self.taskList)
            await searchViewModel.updateBasePredicate(predicate)
        }
    }
    
    func filteredReminders(for subHeading: SubHeading?, searchText: String, tokens: [ReminderToken]) -> [Reminder] {
        var predicates: [NSPredicate] = []
        
        predicates.append(NSPredicate(format: "isCompleted == NO"))
        
        if let subHeading = subHeading {
            predicates.append(NSPredicate(format: "subHeading == %@", subHeading))
        } else {
            predicates.append(NSPredicate(format: "subHeading == nil"))
        }
        
        if !searchText.isEmpty {
            let searchPredicate = NSPredicate(
                format: "title CONTAINS[cd] %@ OR notes CONTAINS[cd] %@",
                searchText, searchText
            )
            predicates.append(searchPredicate)
        }
        
        for token in tokens {
            switch token {
            case .priority(let value):
                predicates.append(NSPredicate(format: "priority == %d", value))
            case .tag(_, let name):
                predicates.append(NSPredicate(format: "ANY tags.name == %@", name))
            @unknown default:
                break
            }
        }
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        let filtered = viewState.reminders
            .filter { reminder in compoundPredicate.evaluate(with: reminder) }
            .sorted { $0.order < $1.order }
        
        logger.debug("Filtered \(filtered.count) reminders from \(self.viewState.reminders.count) total")
        return filtered
    }
    
    func fetchExistingObject<T: NSManagedObject>(with objectID: NSManagedObjectID, as type: T.Type) async -> T? {
        return await reminderService.existingObject(with: objectID, as: type)
    }
    
    func moveItem(_ item: ListItemTransfer, toIndex targetIndex: Int, underSubHeading targetSubHeading: SubHeading?) {
        Task {
            logCurrentState(operation: "State Before Move")
            
            let context = PersistenceController.shared.persistentContainer.viewContext
            
            switch item.type {
            case .reminder:
                moveReminder(withID: item.id, toIndex: targetIndex, underSubHeading: targetSubHeading)
            case .subheading:
                moveSubheading(withID: item.id, toIndex: targetIndex)
            case .group:
                logger.debug("Group moves not implemented")
            @unknown default:
                fatalError("Unknown item type encountered")
            }
            
            try? context.save()
            await updateViewState(.loaded(viewState))
            
            logCurrentState(operation: "State After Move")
        }
    }
    
    private func moveReminder(withID id: UUID, toIndex targetIndex: Int, underSubHeading targetSubHeading: SubHeading?) {
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        guard let reminder = try? context.fetch(fetchRequest).first else {
            logger.error("Failed to fetch reminder with ID: \(id)")
            return
        }
        
        if reminder.subHeading == targetSubHeading {
            reorderReminderWithinSection(reminder, toIndex: targetIndex, inSubHeading: targetSubHeading)
        } else {
            moveReminderAcrossSections(reminder, toIndex: targetIndex, toSubHeading: targetSubHeading)
        }
        
        try? context.save()
    }
    
    private func moveReminderAcrossSections(_ reminder: Reminder, toIndex targetIndex: Int, toSubHeading targetSubHeading: SubHeading?) {
        if let sourceSubHeading = reminder.subHeading {
            sourceSubHeading.removeFromReminders(reminder)
            
            let sourceReminders = fetchCurrentReminders(for: sourceSubHeading)
            for (index, item) in sourceReminders.enumerated() {
                if item != reminder {
                    item.order = Int16(index * 1000)
                }
            }
        } else {
            let mainReminders = fetchCurrentReminders(for: nil)
            for (index, item) in mainReminders.enumerated() {
                if item != reminder {
                    item.order = Int16(index * 1000)
                }
            }
        }
        
        let targetReminders = fetchCurrentReminders(for: targetSubHeading)
        var updatedTargetReminders = targetReminders.filter { $0 != reminder }
        
        let insertIndex = min(targetIndex, updatedTargetReminders.count)
        updatedTargetReminders.insert(reminder, at: insertIndex)
        
        reminder.subHeading = targetSubHeading
        reminder.list = taskList
        
        for (index, item) in updatedTargetReminders.enumerated() {
            item.order = Int16(index * 1000)
        }
        
        if let targetSubHeading = targetSubHeading {
            targetSubHeading.addToReminders(reminder)
        }
    }
    
    private func reorderReminderWithinSection(_ reminder: Reminder, toIndex targetIndex: Int, inSubHeading subHeading: SubHeading?) {
        let currentReminders = fetchCurrentReminders(for: subHeading)
        
        guard let currentIndex = currentReminders.firstIndex(where: { $0.reminderID == reminder.reminderID }) else {
            return
        }
        
        if currentIndex == targetIndex {
            return
        }
        
        var reorderedReminders = currentReminders
        reorderedReminders.remove(at: currentIndex)
        let finalIndex = min(targetIndex, reorderedReminders.count)
        reorderedReminders.insert(reminder, at: finalIndex)
        
        for (index, item) in reorderedReminders.enumerated() {
            item.order = Int16(index * 1000)
        }
        
        if let subHeading = subHeading {
            subHeading.removeFromReminders(reminder)
            subHeading.addToReminders(reminder)
        }
    }
    
    private func moveSubheading(withID id: UUID, toIndex targetIndex: Int) {
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<SubHeading> = SubHeading.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "subheadingID == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        guard let subHeading = try? context.fetch(fetchRequest).first else {
            return
        }
        
        let currentSubHeadings = Array(taskList.subHeadings?.allObjects as? [SubHeading] ?? [])
            .sorted { $0.order < $1.order }
        
        guard let currentIndex = currentSubHeadings.firstIndex(where: { $0.subheadingID == subHeading.subheadingID }) else {
            return
        }
        
        if currentIndex == targetIndex {
            return
        }
        
        var updatedSubHeadings = currentSubHeadings
        updatedSubHeadings.remove(at: currentIndex)
        
        let finalIndex = min(targetIndex, updatedSubHeadings.count)
        updatedSubHeadings.insert(subHeading, at: finalIndex)
        
        for (index, sub) in updatedSubHeadings.enumerated() {
            let newOrder = Int16(index * 1000)
            sub.order = newOrder
        }
        
        taskList.removeFromSubHeadings(subHeading)
        taskList.addToSubHeadings(subHeading)
        
        try? context.save()
        Task { await updateViewState(.loaded(viewState)) }
    }
    
    nonisolated func updateViewState(_ newState: ViewState<ListDetailViewState>) async {
        await MainActor.run { [weak self] in
            self?.internalState = newState
            if case .error(let message) = newState {
                self?.error = IdentifiableError(message: message)
            }
        }
    }
    
    private func fetchCurrentReminders(for subHeading: SubHeading?) -> [Reminder] {
        if let subHeading = subHeading {
            return (subHeading.reminders?.allObjects as? [Reminder] ?? [])
                .filter { $0.isCompleted == false }
                .sorted { $0.order < $1.order }
        } else {
            return taskList.sortedReminders
                .filter { $0.subHeading == nil && $0.isCompleted == false }
                .sorted { $0.order < $1.order }
        }
    }
    
    private func logCurrentState(operation: String) {
        let subheadings = subHeadingsArray
        logger.debug("\(operation) - Subheadings count: \(subheadings.count)")
        for (index, subheading) in subheadings.enumerated() {
            let subheadingReminders = fetchCurrentReminders(for: subheading)
            logger.debug("Subheading \(index): \(subheading.title ?? "untitled") has \(subheadingReminders.count) reminders")
            subheadingReminders.forEach { reminder in
                logger.debug("  - Reminder: \(reminder.title ?? "untitled") Order: \(reminder.order)")
            }
        }
        let mainReminders = fetchCurrentReminders(for: nil)
        logger.debug("Main section has \(mainReminders.count) reminders")
        mainReminders.forEach { reminder in
            logger.debug("  - Reminder: \(reminder.title ?? "untitled") Order: \(reminder.order)")
        }
    }
    
    func reloadRemindersState() async {
        do {
            let reminders = try await loadContent()
            viewState.reminders = reminders
            logger.debug("Reloaded \(reminders.count) reminders")
        } catch {
            logger.error("Failed to reload reminders: \(error.localizedDescription)")
            handleError(error)
        }
    }
}
