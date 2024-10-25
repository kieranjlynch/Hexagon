//
//  AddReminderViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI
import CoreLocation
import os
import AVFoundation
import HexagonData

@MainActor
public class AddReminderViewModel: ObservableObject {
    @AppStorage("preferredTaskType") public var preferredTaskType: String = "Tasks"
    @Published public var title: String = ""
    @Published public var startDate: Date = Date()
    @Published public var endDate: Date = Date()
    @Published public var selectedList: TaskList?
    @Published public var priority: Int = 0
    @Published public var url: String = ""
    @Published public var selectedNotifications: Set<String> = []
    @Published public var selectedTags: Set<ReminderTag> = []
    @Published public var notes: String = ""
    @Published public var selectedPhotos: [UIImage] = []
    @Published public var selectedLocation: Location?
    @Published public var isShowingImagePicker = false
    @Published public var isShowingNewTagAlert = false
    @Published public var newTagName: String = ""
    @Published public var expandedPhotoIndex: Int?
    @Published public var errorMessage: String?
    @Published public var voiceNoteData: Data?
    
    public var reminder: Reminder?
    public var reminderService: ReminderService!
    public var locationService: LocationService!
    public var tagService: TagService!
    public var listService: ListService!
    
    private var logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.hexagon", category: "AddReminderViewModel")
    
    public init(reminder: Reminder? = nil, defaultList: TaskList? = nil) {
        self.reminder = reminder
        if let reminder = reminder {
            loadReminder(reminder)
        } else if let defaultList = defaultList {
            selectedList = defaultList
        }
    }
    
    private func loadReminder(_ reminder: Reminder) {
        title = reminder.title ?? ""
        startDate = reminder.startDate ?? Date()
        endDate = reminder.endDate ?? Date()
        selectedTags = reminder.tags as? Set<ReminderTag> ?? []
        selectedList = reminder.list
        notes = reminder.notes ?? ""
        url = reminder.url ?? ""
        priority = Int(reminder.priority)
        selectedPhotos = (reminder.photos as? Set<ReminderPhoto> ?? []).compactMap { UIImage(data: $0.photoData ?? Data()) }
        selectedNotifications = Set(reminder.notifications?.components(separatedBy: ",") ?? [])
        selectedLocation = reminder.location
        voiceNoteData = reminder.voiceNote?.audioData
    }
    
    public var isFormValid: Bool {
        !title.isEmpty
    }
    
    public func updatePhotos(_ newPhotos: [UIImage]) {
        self.selectedPhotos = newPhotos
    }
    
    // MARK: - Async/Await for saving the reminder

    public func saveReminder() async throws -> (Reminder, [String], [UIImage]) {
        guard let reminderService = reminderService, let _ = listService else {
            throw ReminderError.missingServices
        }
        
        try validateReminderData()
        
        let locationCoordinate = selectedLocation.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        
        logger.debug("Saving reminder with priority: \(self.priority)")
        
        let targetList: TaskList
        if let selectedList = selectedList {
            targetList = selectedList
        } else {
            targetList = try await fetchInboxList()
        }
        
        let savedReminder = try await reminderService.saveReminder(
            reminder: reminder,
            title: title,
            startDate: startDate,
            endDate: endDate,
            notes: notes,
            url: ensureValidURL(url),
            priority: Int16(priority),
            list: targetList,
            subHeading: nil,
            tags: selectedTags,
            photos: selectedPhotos,
            notifications: selectedNotifications,
            location: locationCoordinate,
            radius: 100,
            voiceNoteData: voiceNoteData
        )
        
        self.reminder = savedReminder
        logger.debug("Saved reminder with priority: \(savedReminder.priority)")
        
        return (savedReminder, selectedTags.compactMap { $0.name }, selectedPhotos)
    }
    
    private func fetchInboxList() async throws -> TaskList {
        guard let listService = listService else {
            throw ReminderError.missingServices
        }
        return try await listService.fetchInboxList()
    }
    
    // MARK: - Helper Methods for Validation and URL Formatting

    private func validateReminderData() throws {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ReminderError.emptyTitle
        }
    }
    
    public func ensureValidURL(_ urlString: String) -> String {
        if urlString.isEmpty {
            return ""
        } else if urlString.lowercased().hasPrefix("http://") || urlString.lowercased().hasPrefix("https://") {
            return urlString
        } else {
            return "https://" + urlString
        }
    }
    
    public func saveVoiceNoteDataToFile(data: Data) -> URL? {
        let audioFilename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("voiceNote.m4a")
        do {
            try data.write(to: audioFilename)
            return audioFilename
        } catch {
            return nil
        }
    }
    
    // MARK: - Location Services and Tag Management

    public func searchLocations(query: String) async throws -> [SearchResult] {
        return try await locationService.search(with: query, coordinate: locationService.currentLocation)
    }
    
    public func startLocationUpdates() {
        locationService.startUpdatingLocation()
    }
    
    public func requestLocationPermission() {
        locationService.requestWhenInUseAuthorization()
    }
    
    public func addNewTag() async throws {
        guard !newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard reminderService != nil else {
            throw ReminderError.missingServices
        }
        let newTag = try await tagService.createTag(name: newTagName)
        selectedTags.insert(newTag)
        newTagName = ""
    }
    
    // MARK: - Error Handling

    public enum ReminderError: Error {
        case emptyTitle
        case saveFailed(Error)
        case missingServices
    }
}
