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
final class ListDetailViewModel: ObservableObject, ViewModel, ViewStateManaging, ErrorHandling, TaskManaging, LoggerProvider {
    typealias State = ListDetailViewState
    
    @Published private(set) var viewState: ListDetailViewState
    @Published var error: IdentifiableError?
    @Published var state: ViewState<ListDetailViewState> = .idle
    
    var activeTasks = Set<Task<Void, Never>>()
    var cancellables = Set<AnyCancellable>()
    
    let logger: Logger
    
    let taskList: TaskList
    var reminders: [Reminder] { viewState.reminders }
    var listSymbol: String { viewState.listSymbol }
    
    private let reminderService: ReminderServiceFacade
    private let subHeadingService: SubHeadingServiceFacade
    private let performanceMonitor: PerformanceMonitoring?
    private weak var parentViewModel: ListDetailViewModel?
    
    private var isSearchSetupComplete = false
    private var isLoadingContent = false
    private var isInitialized = false
    
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
        
        if parentViewModel == nil {
            print("INFO: Initializing root ListDetailViewModel for list: \(taskList.name ?? "unnamed")")
            print("INFO: List ID: \(taskList.listID?.uuidString ?? "no ID")")
            setupObservers()
            Task {
                await loadInitialState()
            }
        }
    }
    
    // MARK: - ViewModel Lifecycle Methods
    
    func viewDidLoad() {
        // Implement any setup needed when the view loads
    }
    
    func viewWillAppear() {
        // Implement any actions needed when the view appears
    }
    
    func viewWillDisappear() {
        // Implement any cleanup needed when the view disappears
    }
    
    // MARK: - ViewStateManaging Methods
    
    func updateViewState(_ newState: ViewState<ListDetailViewState>) {
        state = newState
        if case .error(let message) = newState {
            error = IdentifiableError(message: message)
        }
    }
    
    // MARK: - ErrorHandling Method
    
    func handleError(_ error: Error) {
        self.error = IdentifiableError(error: error)
    }
    
    // MARK: - Data Loading
    
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
            async let subHeadings = subHeadingService.fetchSubHeadings(for: taskList)
            
            let (loadedReminders, loadedSubHeadings) = try await (reminders, subHeadings)
            viewState.reminders = loadedReminders
            viewState.subHeadings = loadedSubHeadings
            updateViewState(.loaded(viewState))
        } catch {
            handleError(error)
        }
    }
    
    func loadContent() async throws -> [Reminder] {
        guard !isLoadingContent else { return [] }
        isLoadingContent = true
        defer { isLoadingContent = false }
        
        print("INFO: Loading content for list: \(taskList.name ?? "unknown")")
        await performanceMonitor?.startOperation("LoadContent")
        defer { Task { await performanceMonitor?.endOperation("LoadContent") } }
        
        let fetchedReminders = try await reminderService.fetchReminders(for: taskList, isCompleted: false)
        return fetchedReminders
    }
    
    // MARK: - Data Handling
    
    var subHeadingsArray: [SubHeading] {
        if let parent = parentViewModel {
            return parent.subHeadingsArray
        }
        return viewState.subHeadings.sorted { ($0.order, $0.title ?? "") < ($1.order, $1.title ?? "") }
    }
    
    func sortReminders(by sortType: ReminderSortType) async {
        do {
            let reminders = try await reminderService.fetchSortedReminders(for: taskList, sortType: sortType)
            await MainActor.run {
                viewState.reminders = reminders
                updateViewState(.loaded(viewState))
            }
        } catch {
            handleError(error)
            print("ERROR: Failed to sort reminders: \(error.localizedDescription)")
        }
    }
    
    func toggleCompletion(_ reminder: Reminder) async {
        do {
            let updatedReminder = try await reminderService.toggleCompletion(reminder)
            if let index = reminders.firstIndex(of: reminder) {
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
            let predicate = NSPredicate(format: "list == %@ AND isCompleted == NO", taskList)
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
        
        return reminders
            .filter { reminder in compoundPredicate.evaluate(with: reminder) }
            .sorted { $0.order < $1.order }
    }
    
    func fetchExistingObject<T: NSManagedObject>(with objectID: NSManagedObjectID, as type: T.Type) async -> T? {
        return await reminderService.existingObject(with: objectID, as: type)
    }
    
    // MARK: - Move and Reorder Items
    
    func moveItem(_ item: ListItemTransfer, toIndex targetIndex: Int, underSubHeading targetSubHeading: SubHeading?) {
        print("DEBUG: -------- Moving Item --------")
        print("DEBUG: Item type: \(item.type)")
        print("DEBUG: Target index: \(targetIndex)")
        print("DEBUG: Target subheading: \(targetSubHeading?.title ?? "none")")
        
        logCurrentState(operation: "State Before Move")
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        
        switch item.type {
        case .reminder:
            moveReminder(withID: item.id, toIndex: targetIndex, underSubHeading: targetSubHeading)
        case .subheading:
            moveSubheading(withID: item.id, toIndex: targetIndex)
        case .group:
            print("DEBUG: Group moves not implemented")
        @unknown default:
            print("DEBUG: Unknown item type")
            fatalError("Unknown item type encountered")
        }
        
        try? context.save()
        updateViewState()
        
        logCurrentState(operation: "State After Move")
    }
    
    private func moveReminder(withID id: UUID, toIndex targetIndex: Int, underSubHeading targetSubHeading: SubHeading?) {
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        guard let reminder = try? context.fetch(fetchRequest).first else {
            print("DEBUG: Failed to fetch reminder with ID: \(id)")
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
    
    private func updateViewState() {
        let context = PersistenceController.shared.persistentContainer.viewContext
        let reminderFetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        reminderFetchRequest.predicate = NSPredicate(format: "list == %@ AND isCompleted == %@", taskList, NSNumber(value: false))
        reminderFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.order, ascending: true)]
        
        if let updatedReminders = try? context.fetch(reminderFetchRequest) {
            viewState.reminders = updatedReminders
            self.objectWillChange.send()
            NotificationCenter.default.post(name: .reminderUpdated, object: nil)
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
        updateViewState()
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
        print("\nDEBUG: -------- \(operation) --------")
        print("\nDEBUG: Subheadings:")
        let subheadings = subHeadingsArray
        for (index, subheading) in subheadings.enumerated() {
            print("DEBUG: [\(index)] \(subheading.title ?? "untitled") (Order: \(subheading.order))")
            let subheadingReminders = fetchCurrentReminders(for: subheading)
            subheadingReminders.forEach { reminder in
                print("DEBUG:     - \(reminder.title ?? "untitled") (Order: \(reminder.order))")
            }
        }
        
        print("\nDEBUG: Main section (no subheading):")
        let mainReminders = fetchCurrentReminders(for: nil)
        mainReminders.forEach { reminder in
            print("DEBUG: - \(reminder.title ?? "untitled") (Order: \(reminder.order))")
        }
        print("\nDEBUG: --------------------------------\n")
    }
    
    // MARK: - Reload State
    
    func reloadRemindersState() async {
        do {
            let reminders = try await loadContent()
            viewState.reminders = reminders
        } catch {
            handleError(error)
        }
    }
}
