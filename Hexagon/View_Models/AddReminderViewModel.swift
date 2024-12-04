//
//  AddReminderViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import CoreData
import SwiftUI
import os
import Combine


enum RepeatOption: String, CaseIterable, Codable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    case custom = "Custom"
}

struct AddReminderState: Equatable {
    var title: String = ""
    var startDate: Date = Date()
    var endDate: Date?
    var selectedList: TaskList?
    var priority: Int = 0
    var url: String = ""
    var selectedNotifications: Set<String> = []
    var selectedTags: Set<ReminderTag> = []
    var notes: String = ""
    var selectedPhotos: [UIImage] = []
    var isShowingImagePicker = false
    var isShowingNewTagAlert = false
    var newTagName: String = ""
    var expandedPhotoIndex: Int?
    var voiceNoteData: Data?
    var repeatOption: RepeatOption = .none
    var customRepeatInterval: Int = 1
    
    static func == (lhs: AddReminderState, rhs: AddReminderState) -> Bool {
        lhs.title == rhs.title &&
        lhs.startDate == rhs.startDate &&
        lhs.endDate == rhs.endDate &&
        lhs.priority == rhs.priority &&
        lhs.url == rhs.url &&
        lhs.selectedNotifications == rhs.selectedNotifications &&
        lhs.notes == rhs.notes &&
        lhs.isShowingImagePicker == rhs.isShowingImagePicker &&
        lhs.isShowingNewTagAlert == rhs.isShowingNewTagAlert &&
        lhs.newTagName == rhs.newTagName &&
        lhs.expandedPhotoIndex == rhs.expandedPhotoIndex &&
        lhs.repeatOption == rhs.repeatOption &&
        lhs.customRepeatInterval == rhs.customRepeatInterval
    }
}

@MainActor
final class AddReminderViewModel: ViewModel, ObservableObject {
    @AppStorage("preferredTaskType") var preferredTaskType: String = "Tasks"
    @Published private(set) var viewState: ViewState<AddReminderState>
    @Published var error: IdentifiableError?
    
    var activeTasks = Set<Task<Void, Never>>()
    var cancellables = Set<AnyCancellable>()
    
    private var shouldSyncEndDate = true
    private let reminderCreator: ReminderCreating
    private let taskLimitChecker: TaskLimitChecking
    private let tagService: TagService
    private let listService: any ListServiceProtocol
    private var cachedState: ReminderViewStateAccessor?
    private var lastReadTitle: String = ""
    private var lastReadStartDate: Date = Date()
    private var lastReadEndDate: Date? = nil
    private var lastReadPriority: Int = 0
    var reminder: Reminder?
    
    private var currentViewState: ReminderViewStateAccessor {
        if let cached = cachedState {
            return cached
        }
        
        let newState: ReminderViewStateAccessor
        switch viewState {
        case .loaded(let state):
            newState = ReminderViewStateAccessor(from: state)
        case .loading:
            if let lastState = (try? viewState.get()) {
                newState = ReminderViewStateAccessor(from: lastState)
            } else {
                newState = ReminderViewStateAccessor(from: AddReminderState())
            }
        default:
            newState = ReminderViewStateAccessor(from: AddReminderState())
        }
        
        cachedState = newState
        return newState
    }
    
    init(
        reminder: Reminder? = nil,
        defaultList: TaskList? = nil,
        reminderCreator: ReminderCreating,
        taskLimitChecker: TaskLimitChecking,
        tagService: TagService,
        listService: any ListServiceProtocol
    ) {
        self.reminder = reminder
        self.reminderCreator = reminderCreator
        self.taskLimitChecker = taskLimitChecker
        self.tagService = tagService
        self.listService = listService
        
        self.viewState = .loaded(AddReminderState())
        
        if let reminder = reminder {
            loadReminder(reminder)
        } else if let defaultList = defaultList {
            updateState { state in
                state.selectedList = defaultList
            }
        }
        
        setupBindings()
    }
    
    private func updateState(_ update: (inout AddReminderState) -> Void) {
        guard case .loaded(var state) = viewState else { return }
        
        let oldTitle = state.title
        let oldStartDate = state.startDate
        let oldEndDate = state.endDate
        let oldPriority = state.priority
        
        update(&state)
        
        if oldTitle != state.title {
        }
        if oldStartDate != state.startDate {
        }
        if oldEndDate != state.endDate {
        }
        if oldPriority != state.priority {
        }
        viewState = .loaded(state)
        cachedState = nil
    }
    
    var title: String {
        get {
            let currentTitle = currentViewState.title
            if currentTitle != lastReadTitle {
                lastReadTitle = currentTitle
            }
            return currentTitle
        }
        set {
            if newValue != currentViewState.title {
                updateState { $0.title = newValue }
            }
        }
    }
    
    var startDate: Date {
        get {
            let currentDate = currentViewState.startDate
            if currentDate != lastReadStartDate {
                lastReadStartDate = currentDate
            }
            return currentDate
        }
        set {
            if newValue != currentViewState.startDate {
                updateState { state in
                    state.startDate = newValue
                    if shouldSyncEndDate {
                        state.endDate = newValue
                    }
                }
            }
        }
    }
    
    var endDate: Date? {
        get {
            let currentDate = currentViewState.endDate
            if currentDate != lastReadEndDate {
                lastReadEndDate = currentDate
            }
            return currentDate
        }
        set {
            if newValue != currentViewState.endDate {
                updateState { state in
                    state.endDate = newValue
                    shouldSyncEndDate = false
                }
            }
        }
    }
    
    var priority: Int {
        get {
            let currentPriority = currentViewState.priority
            if currentPriority != lastReadPriority {
                lastReadPriority = currentPriority
            }
            return currentPriority
        }
        set {
            if newValue != currentViewState.priority {
                updateState { $0.priority = newValue }
            }
        }
    }
    
    var selectedList: TaskList? {
        get { currentViewState.selectedList }
        set {
            updateState { $0.selectedList = newValue }
        }
    }
    
    var url: String {
        get { currentViewState.url }
        set {
            updateState { $0.url = newValue }
        }
    }
    
    var selectedNotifications: Set<String> {
        get { currentViewState.notifications }
        set {
            updateState { $0.selectedNotifications = newValue }
        }
    }
    
    var selectedTags: Set<ReminderTag> {
        get { currentViewState.tags }
        set {
            updateState { $0.selectedTags = newValue }
        }
    }
    
    var notes: String {
        get { currentViewState.notes }
        set {
            updateState { $0.notes = newValue }
        }
    }
    
    var selectedPhotos: [UIImage] {
        get { currentViewState.photos }
        set {
            updateState { $0.selectedPhotos = newValue }
        }
    }
    
    var isShowingImagePicker: Bool {
        get { currentViewState.isShowingImagePicker }
        set {
            updateState { $0.isShowingImagePicker = newValue }
        }
    }
    
    var isShowingNewTagAlert: Bool {
        get { currentViewState.isShowingNewTagAlert }
        set {
            updateState { $0.isShowingNewTagAlert = newValue }
        }
    }
    
    var newTagName: String {
        get { currentViewState.newTagName }
        set {
            updateState { $0.newTagName = newValue }
        }
    }
    
    var expandedPhotoIndex: Int? {
        get { currentViewState.expandedPhotoIndex }
        set {
            updateState { $0.expandedPhotoIndex = newValue }
        }
    }
    
    var voiceNoteData: Data? {
        get { currentViewState.voiceNoteData }
        set {
            updateState { $0.voiceNoteData = newValue }
        }
    }
    
    var repeatOption: RepeatOption {
        get { currentViewState.repeatOption }
        set {
            updateState { $0.repeatOption = newValue }
        }
    }
    
    var customRepeatInterval: Int {
        get { currentViewState.customRepeatInterval }
        set {
            updateState { $0.customRepeatInterval = newValue }
        }
    }
    
    var isFormValid: Bool {
        currentViewState.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
    
    func checkTaskLimits() async throws -> Bool {
        let state = currentViewState
        viewState = .loading
        
        do {
            if try await !taskLimitChecker.canAddTaskWithStartDate(state.startDate, excluding: reminder?.reminderID) {
                throw ReminderError.exceededStartDateLimit
            }
            
            if let endDate = state.endDate {
                if try await !taskLimitChecker.canAddTaskWithEndDate(endDate, excluding: reminder?.reminderID) {
                    throw ReminderError.exceededEndDateLimit
                }
            }
            viewState = .loaded(AddReminderState(
                title: state.title,
                startDate: state.startDate,
                endDate: state.endDate,
                selectedList: state.selectedList,
                priority: state.priority,
                url: state.url,
                selectedNotifications: state.notifications,
                selectedTags: state.tags,
                notes: state.notes,
                selectedPhotos: state.photos,
                repeatOption: state.repeatOption,
                customRepeatInterval: state.customRepeatInterval
            ))
            return true
        } catch {
            viewState = .error(error.localizedDescription)
            throw error
        }
    }
    
    func saveReminder() async throws -> (Reminder, [String], [UIImage]) {
        let state = currentViewState
        guard !state.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReminderError.emptyTitle
        }
        viewState = .loading
        
        do {
            guard try await checkTaskLimits() else {
                throw ReminderError.exceededStartDateLimit
            }
            let targetList = try await fetchTargetList()
            let adjustedEndDate = (state.endDate != state.startDate) ? state.endDate : nil
            
            let savedReminder = try await reminderCreator.saveReminder(
                title: state.title,
                startDate: state.startDate,
                endDate: adjustedEndDate,
                notes: state.notes,
                url: ensureValidURL(state.url),
                priority: Int16(state.priority),
                list: targetList,
                subHeading: nil,
                tags: state.tags,
                photos: state.photos,
                notifications: state.notifications,
                voiceNoteData: nil,
                repeatOption: state.repeatOption.rawValue,
                customRepeatInterval: Int16(state.customRepeatInterval)
            )
            viewState = .loaded(AddReminderState(
                title: state.title,
                startDate: state.startDate,
                endDate: state.endDate,
                selectedList: targetList,
                priority: state.priority,
                url: state.url,
                selectedNotifications: state.notifications,
                selectedTags: state.tags,
                notes: state.notes,
                selectedPhotos: state.photos,
                repeatOption: state.repeatOption,
                customRepeatInterval: state.customRepeatInterval
            ))
            
            self.reminder = savedReminder
            return (savedReminder, state.tags.compactMap { $0.name }, state.photos)
        } catch {
            viewState = .error(error.localizedDescription)
            throw error
        }
    }
    
    func updatePhotos(_ newPhotos: [UIImage]) {
        updateState { $0.selectedPhotos = newPhotos }
    }
    
    func addNewTag() async throws {
        guard case .loaded(var state) = viewState else { return }
        guard !state.newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newTag = try await tagService.createTag(name: state.newTagName)
        if newTag.objectID.isTemporaryID {
            try newTag.managedObjectContext?.save()
        }
        state.selectedTags.insert(newTag)
        state.newTagName = ""
        viewState = .loaded(state)
    }
    
    func viewDidLoad() { }
    
    func viewWillAppear() { }
    
    func viewWillDisappear() { }
    
    private func setupBindings() {
        $viewState
            .dropFirst()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    public func updateViewState(_ newState: ViewState<AddReminderState>) {
        viewState = newState
    }
    
    private func loadReminder(_ reminder: Reminder) {
        let task = Task { [weak self] in
            guard let self = self else { return }
            updateState { state in
                state.title = reminder.title ?? ""
                state.startDate = reminder.startDate ?? Date()
                state.endDate = reminder.endDate
                state.selectedTags = reminder.tags as? Set<ReminderTag> ?? []
                state.selectedList = reminder.list
                state.notes = reminder.notes ?? ""
                state.url = reminder.url ?? ""
                state.priority = Int(reminder.priority)
                state.selectedPhotos = MediaManager.loadPhotos(from: reminder.photos as? Set<ReminderPhoto> ?? [])
                state.selectedNotifications = Set(reminder.notifications?.components(separatedBy: ",") ?? [])
                state.voiceNoteData = reminder.voiceNote?.audioData
                if let repeatString = reminder.repeatOption {
                    state.repeatOption = RepeatOption(rawValue: repeatString) ?? .none
                }
                state.customRepeatInterval = Int(reminder.customRepeatInterval)
            }
        }
        activeTasks.insert(task)
    }
    
    private func fetchTargetList() async throws -> TaskList {
        guard case .loaded(let state) = viewState else {
            throw ReminderError.missingServices
        }
        
        do {
            if let selectedList = state.selectedList {
                if selectedList.objectID.isTemporaryID {
                    try selectedList.managedObjectContext?.save()
                }
                return selectedList
            }
            
            let inbox = try await listService.fetchInboxList()
            if inbox.objectID.isTemporaryID {
                try inbox.managedObjectContext?.save()
            }
            await MainActor.run {
                updateState { $0.selectedList = inbox }
            }
            return inbox
        } catch {
            viewState = .error(error.localizedDescription)
            throw error
        }
    }
    
    private func ensureValidURL(_ urlString: String) -> String {
        guard !urlString.isEmpty else { return "" }
        guard !urlString.lowercased().hasPrefix("http://"), !urlString.lowercased().hasPrefix("https://") else {
            return urlString
        }
        return "https://" + urlString
    }
}

extension AddReminderViewModel {
    enum ReminderError: Error, LocalizedError {
        case emptyTitle
        case saveFailed(Error)
        case missingServices
        case exceededStartDateLimit
        case exceededEndDateLimit
        
        var errorDescription: String? {
            switch self {
            case .emptyTitle:
                return "Title cannot be empty"
            case .saveFailed(let error):
                return "Failed to save reminder: \(error.localizedDescription)"
            case .missingServices:
                return "Required services are not available"
            case .exceededStartDateLimit:
                return "Maximum number of tasks already started for this date"
            case .exceededEndDateLimit:
                return "Maximum number of tasks already scheduled for completion on this date"
            }
        }
    }
}

private struct ReminderViewStateAccessor {
    let title: String
    let startDate: Date
    let endDate: Date?
    let selectedList: TaskList?
    let priority: Int
    let url: String
    let notifications: Set<String>
    let tags: Set<ReminderTag>
    let notes: String
    let photos: [UIImage]
    let repeatOption: RepeatOption
    let customRepeatInterval: Int
    let isShowingImagePicker: Bool
    let isShowingNewTagAlert: Bool
    let newTagName: String
    let expandedPhotoIndex: Int?
    let voiceNoteData: Data?
    
    init(from state: AddReminderState) {
        self.title = state.title
        self.startDate = state.startDate
        self.endDate = state.endDate
        self.selectedList = state.selectedList
        self.priority = state.priority
        self.url = state.url
        self.notifications = state.selectedNotifications
        self.tags = state.selectedTags
        self.notes = state.notes
        self.photos = state.selectedPhotos
        self.repeatOption = state.repeatOption
        self.customRepeatInterval = state.customRepeatInterval
        self.isShowingImagePicker = state.isShowingImagePicker
        self.isShowingNewTagAlert = state.isShowingNewTagAlert
        self.newTagName = state.newTagName
        self.expandedPhotoIndex = state.expandedPhotoIndex
        self.voiceNoteData = state.voiceNoteData
    }
}
