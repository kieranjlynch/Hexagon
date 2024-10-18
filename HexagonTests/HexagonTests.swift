//
//  HexagonTests.swift
//  HexagonTests
//
//  Created by Kieran Lynch on 26/09/2024.
//

import Testing
import CoreData
import CoreLocation
import UIKit
import HexagonData

@testable import Hexagon

@MainActor
@Suite("HexagonTests")
struct HexagonTests {
    
    nonisolated let testPersistenceController: PersistenceController
    let reminderService: ReminderService
    let listService: ListService
    let tagService: TagService
    let calendarService: CalendarService
    let photoService: PhotoService
    let locationService: LocationService
    let subheadingService: SubheadingService
    
    init() {
        _ = Bundle(for: PersistenceController.self)
        testPersistenceController = PersistenceController.inMemoryController()
        
        listService = ListService(persistenceController: testPersistenceController)
        tagService = TagService(persistenceController: testPersistenceController)
        calendarService = CalendarService()
        photoService = PhotoService(persistenceController: testPersistenceController)
        locationService = LocationService()
        
        let context = testPersistenceController.persistentContainer.viewContext
        subheadingService = SubheadingService(context: context)
        
        reminderService = ReminderService(
            persistenceController: testPersistenceController,
            listService: listService,
            tagService: tagService,
            calendarService: calendarService,
            photoService: photoService,
            locationService: locationService,
            subheadingService: subheadingService
        )
    }
    
    @Suite("ReminderService Tests")
    struct ReminderServiceTests {
        let reminderService: ReminderService
        
        init(_ parent: HexagonTests) {
            self.reminderService = parent.reminderService
        }
        
        @Test("Save and Fetch Reminder")
        func testSaveAndFetchReminder() async throws {
            let title = "Test Reminder \(UUID().uuidString)"
            let startDate = Date()
            let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
            
            let savedReminder = try await reminderService.saveReminder(
                title: title,
                startDate: startDate,
                endDate: endDate,
                notes: "Test notes",
                url: "https://example.com",
                priority: 1,
                list: nil as TaskList?,
                subHeading: nil as SubHeading?,
                tags: [],
                photos: [],
                notifications: [],
                location: nil as CLLocationCoordinate2D?,
                radius: nil as Double?,
                voiceNoteData: nil as Data?
            )
            
            #expect(savedReminder.title == title)
            
            guard let savedStartDate = savedReminder.startDate,
                  let savedEndDate = savedReminder.endDate else {
                throw TestFailure("Saved dates are nil")
            }
            
            let startDateDifference = abs(savedStartDate.timeIntervalSince(startDate))
            let endDateDifference = abs(savedEndDate.timeIntervalSince(endDate))
            
            let allowedTimeDifference: TimeInterval = 5
            
            #expect(startDateDifference < allowedTimeDifference, "Start date difference should be less than \(allowedTimeDifference) seconds")
            #expect(endDateDifference < allowedTimeDifference, "End date difference should be less than \(allowedTimeDifference) seconds")
            
            let originalTimeDifference = endDate.timeIntervalSince(startDate)
            let savedTimeDifference = savedEndDate.timeIntervalSince(savedStartDate)
            let timeDifferenceDelta = abs(savedTimeDifference - originalTimeDifference)
            
            #expect(timeDifferenceDelta < allowedTimeDifference, "Time difference between start and end dates should be preserved within \(allowedTimeDifference) seconds")
        }
        
        @Test("Update Reminder Completion Status")
        func testUpdateReminderCompletionStatus() async throws {
            let title = "Test Completion Status"
            let savedReminder = try await reminderService.saveReminder(
                title: title,
                startDate: Date(),
                endDate: nil as Date?,
                notes: nil as String?,
                url: nil as String?,
                priority: 0,
                list: nil as TaskList?,
                subHeading: nil as SubHeading?,
                tags: [],
                photos: [],
                notifications: [],
                location: nil as CLLocationCoordinate2D?,
                radius: nil as Double?,
                voiceNoteData: nil as Data?
            )
            
            try await reminderService.updateReminderCompletionStatus(reminder: savedReminder, isCompleted: true)
            
            let updatedReminders = try await reminderService.fetchReminders()
            guard let updatedReminder = updatedReminders.first(where: { $0.title == title }) else {
                throw TestFailure("Updated reminder not found")
            }
            
            #expect(updatedReminder.isCompleted == true)
        }
        
        @Test("Delete Reminder")
        func testDeleteReminder() async throws {
            let reminder = try await reminderService.saveReminder(
                title: "Delete Me",
                startDate: Date(),
                endDate: nil,
                notes: nil,
                url: nil,
                priority: 0,
                list: nil,
                subHeading: nil,
                tags: [],
                photos: [],
                notifications: [],
                location: nil,
                radius: nil,
                voiceNoteData: nil
            )
            
            try await reminderService.deleteReminder(reminder)
            
            let fetchedReminders = try await reminderService.fetchReminders()
            #expect(!fetchedReminders.contains(where: { $0.title == "Delete Me" }))
        }
        
        @Test("Update Reminder")
        func testUpdateReminder() async throws {
            let reminder = try await reminderService.saveReminder(
                title: "Update Me",
                startDate: Date(),
                endDate: nil,
                notes: nil,
                url: nil,
                priority: 0,
                list: nil,
                subHeading: nil,
                tags: [],
                photos: [],
                notifications: [],
                location: nil,
                radius: nil,
                voiceNoteData: nil
            )
            
            let updatedReminder = try await reminderService.saveReminder(
                reminder: reminder,
                title: "Updated",
                startDate: reminder.startDate ?? Date(),
                endDate: reminder.endDate,
                notes: reminder.notes,
                url: reminder.url,
                priority: 2,
                list: reminder.list,
                subHeading: reminder.subHeading,
                tags: reminder.tags as? Set<ReminderTag> ?? [],
                photos: [],
                notifications: Set(reminder.notifications?.components(separatedBy: ",") ?? []),
                location: nil,
                radius: reminder.radius,
                voiceNoteData: reminder.voiceNote?.audioData
            )
            
            #expect(updatedReminder.title == "Updated")
            #expect(updatedReminder.priority == 2)
            
            let fetchedReminders = try await reminderService.fetchReminders()
            guard let fetchedUpdatedReminder = fetchedReminders.first(where: { $0.title == "Updated" }) else {
                throw TestFailure("Updated reminder not found")
            }
            
            #expect(fetchedUpdatedReminder.title == "Updated")
            #expect(fetchedUpdatedReminder.priority == 2)
        }
        
        @Test("Fetch Reminders by Date Range")
        func testFetchRemindersByDateRange() async throws {
            let startDate = Date()
            let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
            
            _ = try await reminderService.saveReminder(
                title: "In Range 1",
                startDate: Calendar.current.date(byAdding: .day, value: 1, to: startDate)!,
                endDate: nil,
                notes: nil,
                url: nil,
                priority: 0,
                list: nil,
                subHeading: nil,
                tags: [],
                photos: [],
                notifications: [],
                location: nil,
                radius: nil,
                voiceNoteData: nil
            )
            
            _ = try await reminderService.saveReminder(
                title: "In Range 2",
                startDate: Calendar.current.date(byAdding: .day, value: 3, to: startDate)!,
                endDate: nil,
                notes: nil,
                url: nil,
                priority: 0,
                list: nil,
                subHeading: nil,
                tags: [],
                photos: [],
                notifications: [],
                location: nil,
                radius: nil,
                voiceNoteData: nil
            )
            
            let _ = try await reminderService.saveReminder(
                title: "Out of Range",
                startDate: Calendar.current.date(byAdding: .day, value: 10, to: startDate)!,
                endDate: nil,
                notes: nil,
                url: nil,
                priority: 0,
                list: nil,
                subHeading: nil,
                tags: [],
                photos: [],
                notifications: [],
                location: nil,
                radius: nil,
                voiceNoteData: nil
            )
            
            let fetchedReminders = try await reminderService.fetchReminders(
                withPredicate: "startDate >= %@ AND startDate <= %@",
                predicateArguments: [startDate, endDate]
            )
            
            #expect(fetchedReminders.count == 2)
            #expect(fetchedReminders.contains(where: { $0.title == "In Range 1" }))
            #expect(fetchedReminders.contains(where: { $0.title == "In Range 2" }))
            #expect(!fetchedReminders.contains(where: { $0.title == "Out of Range" }))
        }
    }
}
