//
//  ListDetailViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 17/09/2024.
//

import SwiftUI
import CoreData
import HexagonData
import DragAndDrop
import CoreGraphics

public enum DropTargetType: Equatable {
    case subheading(UUID)
    case noSubheading
}

public class ListDropReceiver: DropReceiver {
    public let targetType: DropTargetType
    public var dropArea: CGRect?

    public init(targetType: DropTargetType) {
        self.targetType = targetType
        self.dropArea = nil
    }

    public func updateDropArea(with newDropArea: CGRect) {
        self.dropArea = newDropArea
    }

    public func getDropArea() -> CGRect? {
        return dropArea
    }
}

public class ListDetailViewModel: ObservableObject, DropReceivableObservableObject {
    public typealias DropReceivable = ListDropReceiver

    public func setDropArea(_ dropArea: CGRect, on dropReceiver: DropReceivable) {
        dropReceiver.updateDropArea(with: dropArea)
    }
    
    @Published public var subHeadings: [SubHeading] = []
    @Published public var reminders: [Reminder] = []
    @Published public var error: IdentifiableError?
    @Published public var listSymbol: String
    @Published public var isDraggingReminder = false
    @Published public var isDraggingSubheading = false
    
    private let managedContext: NSManagedObjectContext
    public var context: NSManagedObjectContext {
        managedContext
    }
    
    public let reminderService: ReminderService
    public let locationService: LocationService
    private let subheadingService: SubheadingService
    public let taskList: TaskList
    
    private var notificationObserver: NSObjectProtocol?
    internal var dropReceivers: [DropReceivable] = []
    private var subheadingDropAreas: [NSManagedObjectID: DropReceivable] = [:]
    private var noSubheadingReceiver: DropReceivable?
    
    public init(context: NSManagedObjectContext, taskList: TaskList, reminderService: ReminderService, locationService: LocationService) {
        self.managedContext = context
        self.taskList = taskList
        self.reminderService = reminderService
        self.locationService = locationService
        self.subheadingService = SubheadingService()
        self.listSymbol = taskList.symbol ?? "list.bullet"
        
        setupNotificationObserver()
    }
    
    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func setupDropReceivers() {
        var receivers: [DropReceivable] = []
        subheadingDropAreas.removeAll()
        
        for subheading in subHeadings {
            guard let subheadingID = subheading.subheadingID else { continue }
            let receiver = ListDropReceiver(targetType: .subheading(subheadingID))
            subheadingDropAreas[subheading.objectID] = receiver
            receivers.append(receiver)
        }
        
        let noSubheadingReceiver = ListDropReceiver(targetType: .noSubheading)
        self.noSubheadingReceiver = noSubheadingReceiver
        receivers.append(noSubheadingReceiver)
        
        dropReceivers = receivers
    }
    
    func dropReceiverForSubheading(_ subheading: SubHeading) -> DropReceivable {
        return subheadingDropAreas[subheading.objectID] ?? ListDropReceiver(targetType: .noSubheading)
    }
    
    func dropReceiverForNoSubheading() -> DropReceivable {
        return noSubheadingReceiver ?? ListDropReceiver(targetType: .noSubheading)
    }
    
    func setDraggingReminder(_ isDragging: Bool) {
        isDraggingReminder = isDragging
    }
    
    func setDraggingSubheading(_ isDragging: Bool) {
        isDraggingSubheading = isDragging
    }
    
    func getDropableState(at position: CGPoint) -> Bool {
        return dropReceivers.contains { $0.dropArea?.contains(position) ?? false }
    }
    
    func getDropableStateForSubheading(at position: CGPoint) -> Bool {
        guard let dropReceiver = dropReceivers.first(where: { $0.dropArea?.contains(position) ?? false }) else {
            return false
        }
        switch dropReceiver.targetType {
        case .subheading:
            return true
        case .noSubheading:
            return false
        }
    }
    
    func handleTaskDrop(reminder: Reminder, at position: CGPoint) {
        if let dropReceiver = dropReceivers.first(where: { $0.dropArea?.contains(position) ?? false }) {
            switch dropReceiver.targetType {
            case .subheading(let subheadingID):
                if let targetSubheading = subHeadings.first(where: { $0.subheadingID == subheadingID }) {
                    reminder.subHeading = targetSubheading
                }
            case .noSubheading:
                reminder.subHeading = nil
            }
            Task { @MainActor in
                saveContext()
            }
        }
    }
    
    func handleSubheadingDrop(subheading: SubHeading, at position: CGPoint) {
        if let dropReceiver = dropReceivers.first(where: { $0.dropArea?.contains(position) ?? false }) {
            switch dropReceiver.targetType {
            case .subheading(let targetID):
                guard let targetSubheading = subHeadings.first(where: { $0.subheadingID == targetID }),
                      let currentIndex = subHeadings.firstIndex(of: subheading),
                      let newIndex = subHeadings.firstIndex(of: targetSubheading) else { return }
                
                let adjustedNewIndex = currentIndex < newIndex ? newIndex - 1 : newIndex
                
                if currentIndex != adjustedNewIndex {
                    let movedSubheading = subHeadings.remove(at: currentIndex)
                    subHeadings.insert(movedSubheading, at: adjustedNewIndex)
                    
                    for (index, subheading) in subHeadings.enumerated() {
                        subheading.order = Int16(index)
                    }
                    
                    Task { @MainActor in
                        saveContext()
                    }
                }
            case .noSubheading:
                return
            }
        }
    }
    
    @MainActor
    private func saveContext() {
        do {
            try managedContext.save()
            objectWillChange.send()
        } catch {
            self.error = IdentifiableError(message: error.localizedDescription)
        }
    }
    
    public func filteredReminders(for subHeading: SubHeading?, searchText: String, tokens: [ReminderToken]) -> [Reminder] {
        let reminders = subHeading == nil ?
        self.reminders.filter { $0.subHeading == nil } :
        self.reminders.filter { $0.subHeading == subHeading }
        
        return reminders.filter { reminder in
            var matches = true
            if !searchText.isEmpty {
                let titleMatch = reminder.title?.localizedCaseInsensitiveContains(searchText) ?? false
                let notesMatch = reminder.notes?.localizedCaseInsensitiveContains(searchText) ?? false
                matches = titleMatch || notesMatch
            }
            return matches
        }
    }
    
    public func performSearch(_ searchText: String) {
        objectWillChange.send()
    }
    
    private func setupNotificationObserver() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .reminderAdded,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.refreshRemindersAndSubHeadings()
            }
        }
    }
    
    private func refreshRemindersAndSubHeadings() async {
        await loadContent()
    }
    
    @MainActor
    public func loadContent() async {
        do {
            let fetchedReminders = try await reminderService.getRemindersForList(taskList)
            let fetchedSubHeadings = try await subheadingService.fetchSubHeadings(for: taskList)
            
            self.reminders = fetchedReminders
            self.subHeadings = fetchedSubHeadings
            setupDropReceivers()
        } catch {
            self.error = IdentifiableError(message: error.localizedDescription)
        }
    }
    
    public func toggleCompletion(_ reminder: Reminder) async {
        do {
            try await reminderService.updateReminderCompletionStatus(reminder: reminder, isCompleted: !reminder.isCompleted)
            await loadContent()
        } catch {
            self.error = IdentifiableError(message: error.localizedDescription)
        }
    }
    
    public func updateSubHeading(_ subHeading: SubHeading) async throws {
        do {
            try await subheadingService.updateSubHeading(subHeading, title: subHeading.title ?? "")
            await loadContent()
        } catch {
            self.error = IdentifiableError(message: error.localizedDescription)
            throw error
        }
    }
    
    public func deleteSubHeading(_ subHeading: SubHeading) async throws {
        do {
            try await subheadingService.deleteSubHeading(subHeading)
            await loadContent()
        } catch {
            self.error = IdentifiableError(message: error.localizedDescription)
            throw error
        }
    }
    
    public func deleteReminder(_ reminder: Reminder) async {
        do {
            try await reminderService.deleteReminder(reminder)
            await loadContent()
        } catch {
            self.error = IdentifiableError(message: error.localizedDescription)
        }
    }
    
    @MainActor
    public func setupSearchViewModel(_ searchViewModel: SearchViewModel) {
        searchViewModel.setup(reminderService: reminderService, viewContext: context)
    }
    
    // MARK: - DragAndDrop Methods
    
    func onDraggedReminder(reminder: Dragable, position: CGPoint) -> DragState {
        self.isDraggingReminder = true
        return self.getDropableState(at: position) ? .accepted : .rejected
    }
    
    func onDroppedReminder(reminder: Dragable, position: CGPoint) -> Bool {
        self.isDraggingReminder = false
        self.handleTaskDrop(reminder: reminder as! Reminder, at: position)
        return true
    }
    
    func onDraggedSubheading(position: CGPoint) -> DragState {
        self.isDraggingSubheading = true
        return self.getDropableStateForSubheading(at: position) ? .accepted : .rejected
    }
    
    func onDroppedSubheading(subheading: SubHeading, position: CGPoint) -> Bool {
        self.isDraggingSubheading = false
        self.handleSubheadingDrop(subheading: subheading, at: position)
        return true
    }
}
