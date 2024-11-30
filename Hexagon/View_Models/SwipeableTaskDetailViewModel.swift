
//
//  SwipeableTaskDetailViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 20/09/2024.
//

import SwiftUI
import CoreData
import Combine


struct SwipeableTaskDetailViewState: Equatable {
    var reminders: [Reminder]
    
    init(reminders: [Reminder]) {
        self.reminders = reminders
    }
    
    static func == (lhs: SwipeableTaskDetailViewState, rhs: SwipeableTaskDetailViewState) -> Bool {
        return lhs.reminders.map { $0.objectID } == rhs.reminders.map { $0.objectID }
    }
}

protocol ViewModelProtocol: AnyObject {
    var activeTasks: Set<Task<Void, Never>> { get set }
    var cancellables: Set<AnyCancellable> { get set }
}

extension ViewModelProtocol {
    func cancellAllTasks() {
        activeTasks.forEach { $0.cancel() }
        activeTasks.removeAll()
    }
}

final class CacheEntry: @unchecked Sendable {
    weak var reminder: Reminder?
    var photoData: [Data]?
    var voiceNoteData: Data?
    var associatedData: [String: Any]?
    
    init() {}
    
    func calculateCost() -> Int {
        var cost = 0
        photoData?.forEach { cost += $0.count }
        cost += voiceNoteData?.count ?? 0
        return cost
    }
}

@MainActor
final class SwipeableTaskDetailViewModel: NSObject, @preconcurrency ViewModelProtocol, CacheManaging, ObservableObject {
    @Published private(set) var viewState: SwipeableTaskDetailViewState
    @Published var error: IdentifiableError?
    @Published var state: ViewState<SwipeableTaskDetailViewState> = .idle
    
    var activeTasks = Set<Task<Void, Never>>()
    var cancellables = Set<AnyCancellable>()
    
    private let context: NSManagedObjectContext
    private let modificationService: ReminderModificationService
    private let fetchingService: ReminderFetchingService
    private var fetchedResultsController: NSFetchedResultsController<Reminder>?
    private var pendingChanges: [(NSFetchedResultsChangeType, IndexPath?, IndexPath?)] = []
    private var contentCache: NSCache<NSString, CacheEntry>
    private var isObserving = false
    
    init(reminders: [Reminder]) {
        self.context = PersistenceController.shared.persistentContainer.viewContext
        self.modificationService = ReminderModificationService.shared
        self.fetchingService = ReminderFetchingService.shared
        self.viewState = SwipeableTaskDetailViewState(reminders: reminders)
        self.contentCache = NSCache<NSString, CacheEntry>()
        
        super.init()
        
        configureCache()
        setupFetchedResultsController()
        startObservingMemoryWarnings()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cancellAllTasks()
    }
    
    func viewDidLoad() { }
    
    func viewWillAppear() { }
    
    func viewWillDisappear() {
        Task { @MainActor in
            cleanupResources()
        }
    }
    
    func preloadContent(for indices: [Int]) {
        guard !indices.isEmpty else { return }
        
        let reminders = viewState.reminders
        
        Task.detached {
            for index in indices {
                guard index >= 0, index < reminders.count else { continue }
                
                let reminder = reminders[index]
                let keyString = reminder.objectID.uriRepresentation().absoluteString
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    let key = NSString(string: keyString)
                    
                    if self.contentCache.object(forKey: key) == nil {
                        let entry = CacheEntry()
                        entry.reminder = reminder
                        
                        if let photos = reminder.photos as? Set<ReminderPhoto> {
                            entry.photoData = photos.compactMap { $0.photoData }
                        }
                        
                        if let voiceNote = reminder.voiceNote {
                            entry.voiceNoteData = voiceNote.audioData
                        }
                        
                        self.contentCache.setObject(entry, forKey: key, cost: entry.calculateCost())
                    }
                }
            }
        }
    }
    
    func cleanupContent(for index: Int) {
        guard index >= 0, index < viewState.reminders.count else { return }
        let reminder = viewState.reminders[index]
        let keyString = reminder.objectID.uriRepresentation().absoluteString
        let key = NSString(string: keyString)
        contentCache.removeObject(forKey: key)
    }
    
    func cleanupMemory() {
        contentCache.removeAllObjects()
        cancellAllTasks()
    }
    
    func deleteReminder(at index: Int) async throws {
        guard index < viewState.reminders.count else { return }
        
        let reminderToDelete = viewState.reminders[index]
        let key = NSString(string: reminderToDelete.objectID.uriRepresentation().absoluteString)
        
        let result = await modificationService.deleteReminder(reminderToDelete)
        switch result {
        case .success:
            await MainActor.run { [weak self] in
                self?.viewState.reminders.remove(at: index)
                self?.contentCache.removeObject(forKey: key)
                NotificationCenter.default.post(name: .reminderDeleted, object: nil)
            }
        case .failure(let error):
            throw error
        }
    }
    
    private func configureCache() {
        contentCache.countLimit = 10
        contentCache.totalCostLimit = 50 * 1024 * 1024
        contentCache.evictsObjectsWithDiscardedContent = true
    }
    
    private func setupFetchedResultsController() {
        let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        request.predicate = NSPredicate(format: "SELF IN %@", viewState.reminders)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.order, ascending: true)]
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
    
    private func startObservingMemoryWarnings() {
        guard !isObserving else { return }
        isObserving = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        cleanupMemory()
    }
    
    private func cleanupResources() {
        contentCache.removeAllObjects()
        NotificationCenter.default.removeObserver(self)
        fetchedResultsController?.delegate = nil
        fetchedResultsController = nil
        isObserving = false
        cancellAllTasks()
    }
    
    private func updateReminders(_ reminders: [Reminder]) {
        Task { @MainActor [weak self] in
            self?.viewState.reminders = reminders
        }
    }
}

extension SwipeableTaskDetailViewModel: NSFetchedResultsControllerDelegate {
    nonisolated func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        Task { @MainActor [weak self] in
            self?.pendingChanges.removeAll()
        }
    }
    
    nonisolated func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        Task { @MainActor [weak self] in
            guard let self = self,
                  let reminder = anObject as? Reminder else { return }
            
            switch type {
            case .insert:
                if let newIndexPath = newIndexPath?.item,
                   newIndexPath <= viewState.reminders.count {
                    viewState.reminders.insert(reminder, at: newIndexPath)
                    preloadContent(for: [newIndexPath])
                }
                
            case .delete:
                if let indexPath = indexPath?.item,
                   indexPath < viewState.reminders.count {
                    cleanupContent(for: indexPath)
                    viewState.reminders.remove(at: indexPath)
                }
                
            case .update:
                if let indexPath = indexPath?.item,
                   indexPath < viewState.reminders.count {
                    viewState.reminders[indexPath] = reminder
                    preloadContent(for: [indexPath])
                }
                
            case .move:
                if let indexPath = indexPath?.item,
                   let newIndexPath = newIndexPath?.item,
                   indexPath < viewState.reminders.count,
                   newIndexPath <= viewState.reminders.count {
                    let reminder = viewState.reminders.remove(at: indexPath)
                    viewState.reminders.insert(reminder, at: newIndexPath)
                    cleanupContent(for: indexPath)
                    preloadContent(for: [newIndexPath])
                }
                
            @unknown default:
                break
            }
            
            pendingChanges.append((type, indexPath, newIndexPath))
        }
    }
    
    nonisolated func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            pendingChanges.removeAll()
            if let objects = controller.fetchedObjects as? [Reminder] {
                updateReminders(objects)
            }
        }
    }
}
