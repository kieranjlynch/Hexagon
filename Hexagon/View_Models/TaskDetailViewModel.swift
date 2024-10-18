//
//  TaskDetailViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 19/09/2024.
//

import SwiftUI
import AVFoundation
import HexagonData
import Combine

@MainActor
class TaskDetailViewModel: ObservableObject {
    @Published var reminder: Reminder
    @Published var tags: [String] = []
    @Published var notifications: [String] = []
    @Published var photos: [ReminderPhoto] = []
    @Published var isPlaying = false
    
    private var audioPlayer: AVAudioPlayer?
    private let reminderService: ReminderService
    private var cancellables = Set<AnyCancellable>()
    
    init(reminder: Reminder, reminderService: ReminderService) {
        self.reminder = reminder
        self.reminderService = reminderService
        loadReminderDetails()
    }
    
    // MARK: - Combine Streams
    
    private func setupCombineSubscriptions() {
        $reminder
            .sink { [weak self] _ in
                self?.loadReminderDetails()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Async/Await functions

    func loadReminderDetails() {
        Task {
            await fetchPhotos()
            await fetchTags()
            await fetchNotifications()
        }
    }

    @MainActor
    func updateTags(_ newTags: [String]) {
        self.tags = newTags
    }

    @MainActor
    func updatePhotos(_ newPhotos: [UIImage]) {
        self.photos = newPhotos.compactMap { photo in
            guard let photoData = photo.jpegData(compressionQuality: 0.8) else { return nil }
            let reminderPhoto = ReminderPhoto(context: reminderService.persistentContainer.viewContext)
            reminderPhoto.photoData = photoData
            return reminderPhoto
        }
    }

    @MainActor
    func reloadReminder() async {
        do {
            let updatedReminder = try reminderService.getReminder(withID: reminder.objectID)
            self.reminder = updatedReminder
            loadReminderDetails()
        } catch {
            print("Error reloading reminder: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Async Fetch Operations

    private func fetchPhotos() async {
        if let photosSet = reminder.photos as? Set<ReminderPhoto> {
            photos = Array(photosSet)
        } else {
            photos = []
        }
    }

    private func fetchTags() async {
        if let tagsSet = reminder.tags as? Set<ReminderTag> {
            tags = tagsSet.compactMap { $0.name }
        } else {
            tags = []
        }
    }

    private func fetchNotifications() async {
        if let notificationsString = reminder.notifications {
            notifications = notificationsString.components(separatedBy: ",").filter { !$0.isEmpty }
        } else {
            notifications = []
        }
    }
    
    // MARK: - Playback Management

    func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }
    
    private func startPlayback() {
        guard let audioData = reminder.voiceNote?.audioData else { return }
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
    }
    
    // MARK: - Utility Properties
    
    var hasDates: Bool {
        reminder.startDate != nil || reminder.endDate != nil
    }

    var hasURL: Bool {
        guard let urlString = reminder.url, !urlString.isEmpty else { return false }
        return URL(string: urlString) != nil
    }

    var hasLocation: Bool {
        reminder.location != nil
    }

    var hasVoiceNote: Bool {
        reminder.voiceNote?.audioData != nil
    }

    var priorityText: String {
        switch Int(reminder.priority) {
        case 1: return "Low"
        case 2: return "Medium"
        case 3: return "High"
        default: return "None"
        }
    }
}
