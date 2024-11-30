//
//  TaskDetailViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 19/09/2024.
//

import SwiftUI
import AVFoundation
import Combine
import CoreData
import os


struct TaskDetailState: Equatable {
    var reminder: Reminder
    var tags: [String] = []
    var notifications: [String] = []
    var photos: [ReminderPhoto] = []
    var isPlaying: Bool = false

    static func == (lhs: TaskDetailState, rhs: TaskDetailState) -> Bool {
        lhs.tags == rhs.tags &&
        lhs.notifications == rhs.notifications &&
        lhs.isPlaying == rhs.isPlaying
    }
}

@MainActor
final class TaskDetailViewModel: ViewModel, ReminderDetailsPresenting {
    @Published private(set) var viewState: ViewState<TaskDetailState>
    @Published var error: IdentifiableError?

    var activeTasks = Set<Task<Void, Never>>()
    var cancellables = Set<AnyCancellable>()

    private let audioManager: AudioPlaybackManaging
    private let fetchingService: ReminderFetching
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "TaskDetailViewModel")

    private var currentState: TaskDetailState? {
        switch viewState {
        case .loaded(let state):
            return state
        case .loading:
            return try? viewState.get()
        default:
            return nil
        }
    }

    init(
        reminder: Reminder,
        audioManager: AudioPlaybackManaging,
        fetchingService: ReminderFetching
    ) {
        self.audioManager = audioManager
        self.fetchingService = fetchingService
        self.viewState = .loaded(TaskDetailState(reminder: reminder))
        setupObservers()

        Task {
            await fetchDetails()
        }
    }

    func viewDidLoad() { }

    func viewWillAppear() { }

    func viewWillDisappear() {
        Task {
            await cleanup()
        }
    }

    func loadContent() async throws {
        await fetchDetails()
    }

    func handleLoadedContent(_ content: Void) { }

    func handleLoadError(_ error: Error) {
        logger.error("Failed to load reminder details: \(error.localizedDescription)")
        self.error = IdentifiableError(error: error)
        viewState = .error(error.localizedDescription)
    }

    func togglePlayback() async {
        guard let state = currentState else { return }
        if state.isPlaying {
            stopPlayback()
        } else {
            await startPlayback()
        }
    }

    func stopPlayback() {
        guard case .loaded(var state) = viewState else { return }
        audioManager.stopPlayback()
        state.isPlaying = false
        viewState = .loaded(state)
    }

    func pausePlayback() {
        guard case .loaded(var state) = viewState else { return }
        if state.isPlaying {
            audioManager.pausePlayback()
            state.isPlaying = false
            viewState = .loaded(state)
        }
    }

    func reloadReminder() async {
        viewState = .loading

        do {
            let updatedReminder = try fetchingService.getReminder(withID: currentState?.reminder.objectID ?? reminder.objectID)
            guard case .loaded(var state) = viewState else { return }
            state.reminder = updatedReminder
            viewState = .loaded(state)
            await fetchDetails()
        } catch {
            viewState = .error(error.localizedDescription)
            logger.error("Failed to reload reminder: \(error.localizedDescription)")
        }
    }

    private func setupObservers() {
        $viewState
            .map { viewState -> Reminder? in
                if case .loaded(let state) = viewState {
                    return state.reminder
                }
                return nil
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    try? await self?.loadContent()
                }
            }
            .store(in: &cancellables)
    }

    private func fetchDetails() async {
        await withCheckedContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume()
                return
            }

            Task { @MainActor in
                guard case .loaded(var state) = self.viewState else { return }
                let context = self.fetchingService.context
                await context.perform {
                    state.photos = (self.reminder.photos as? Set<ReminderPhoto>)?.sorted(by: { $0.order < $1.order }) ?? []
                    state.tags = (self.reminder.tags as? Set<ReminderTag>)?.compactMap { $0.name } ?? []
                    state.notifications = (self.reminder.notifications?.components(separatedBy: ",")) ?? []
                }
                self.viewState = .loaded(state)
                continuation.resume()
            }
        }
    }

    private func startPlayback() async {
        await withCheckedContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume()
                return
            }

            Task { @MainActor in
                guard case .loaded(var state) = self.viewState else { return }
                let context = self.fetchingService.context
                await context.perform {
                    guard let audioData = self.reminder.voiceNote?.audioData else { return }
                    do {
                        try self.audioManager.startPlayback(data: audioData)
                        state.isPlaying = true
                        self.viewState = .loaded(state)
                    } catch {
                        self.logger.error("Failed to start playback: \(error.localizedDescription)")
                    }
                }
                continuation.resume()
            }
        }
    }

    @MainActor public func cleanup() async {
        stopPlayback()
    }
}

extension TaskDetailViewModel {
    var reminder: Reminder {
        if let state = currentState {
            return state.reminder
        }
        logger.error("Attempted to access reminder while state not loaded")
        fatalError("Cannot access reminder: State not loaded")
    }

    var tags: [String] {
        currentState?.tags ?? []
    }

    var notifications: [String] {
        currentState?.notifications ?? []
    }

    var photos: [ReminderPhoto] {
        currentState?.photos ?? []
    }

    var isPlaying: Bool {
        currentState?.isPlaying ?? false
    }

    var hasDates: Bool {
        let currentReminder = reminder
        return currentReminder.startDate != nil || currentReminder.endDate != nil
    }

    var hasURL: Bool {
        let currentReminder = reminder
        guard let urlString = currentReminder.url, !urlString.isEmpty else { return false }
        return URL(string: urlString) != nil
    }

    var hasVoiceNote: Bool {
        let currentReminder = reminder
        return currentReminder.voiceNote?.audioData != nil
    }

    var priorityText: String {
        let currentReminder = reminder
        switch Int(currentReminder.priority) {
        case 1: return "Low"
        case 2: return "Medium"
        case 3: return "High"
        default: return "None"
        }
    }
}

@MainActor
final class DefaultAudioManager: ObservableObject, AudioPlaybackManaging {
    @Published private(set) var isPlaying: Bool = false
    private var audioPlayer: AVAudioPlayer?

    func startPlayback(data: Data) throws {
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.play()
        isPlaying = true
    }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }

    func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
    }
}
