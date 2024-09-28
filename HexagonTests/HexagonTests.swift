//
//  HexagonTests.swift
//  HexagonTests
//
//  Created by Kieran Lynch on 26/09/2024.
//

import Testing
import CoreData
import CoreLocation
import HexagonData

@testable import Hexagon

@MainActor
@Suite("HexagonTests")
struct HexagonTests {
    
    let testPersistenceController: PersistenceController
    let reminderService: ReminderService
    
    init() {
        _ = Bundle(for: PersistenceController.self)
        testPersistenceController = PersistenceController.inMemoryController()
        reminderService = ReminderService(persistenceController: testPersistenceController)
    }
    
    @Test("ReminderService - Save and Fetch Reminder")
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
    
    @Test("ReminderService - Update Reminder Completion Status")
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
        
        let updatedReminders = try await reminderService.fetchAllReminders()
        guard let updatedReminder = updatedReminders.first(where: { $0.title == title }) else {
            throw TestFailure("Updated reminder not found")
        }
        
        #expect(updatedReminder.isCompleted == true)
    }
    
    @Test("SubheadingService - Save and Fetch Subheading")
    func testSaveAndFetchSubheading() async throws {
        let context = testPersistenceController.persistentContainer.viewContext
        let subheadingService = SubheadingService(context: context)
        
        let taskList = TaskList(context: context)
        taskList.name = "Test List"
        taskList.listID = UUID()
        try context.save()
        
        let subheadingTitle = "Test Subheading"
        let savedSubheading = try await subheadingService.saveSubHeading(title: subheadingTitle, taskList: taskList)
        
        let fetchedSubheadings = try await subheadingService.fetchSubHeadings(for: taskList)
        
        #expect(!fetchedSubheadings.isEmpty)
        #expect(fetchedSubheadings.contains(where: { $0.title == subheadingTitle }))
        #expect(savedSubheading.taskList == taskList)
    }
    
    @Test("LocationService - Search Locations")
    func testSearchLocations() async throws {
        let locationService = LocationService()
        
        let searchResults = try await locationService.search(with: "Eiffel Tower")
        
        #expect(!searchResults.isEmpty)
        #expect(searchResults.contains(where: { $0.location.latitude != 0 && $0.location.longitude != 0 }))
    }
    
    @Test("AddReminderViewModel - Save Reminder")
    func testSaveReminder() async throws {
        let viewModel = AddReminderViewModel()
        
        await MainActor.run {
            viewModel.reminderService = reminderService
            viewModel.title = "Test Reminder"
            viewModel.startDate = Date()
            viewModel.endDate = Date().addingTimeInterval(3600)
            viewModel.priority = 2
        }
        
        let (savedReminder, _, _) = try await viewModel.saveReminder()
        
        await MainActor.run {
            #expect(savedReminder.title == "Test Reminder")
            #expect(savedReminder.priority == 2)
            #expect(savedReminder.startDate != nil)
            #expect(savedReminder.endDate != nil)
        }
    }
    
    @Test("ListDetailViewModel - Load Content")
    func testLoadContent() async throws {
        let context = testPersistenceController.persistentContainer.viewContext
        let reminderService = ReminderService(persistenceController: testPersistenceController)
        
        let taskList = TaskList(context: context)
        taskList.name = "Test List"
        taskList.listID = UUID()
        try context.save()
        
        let reminder = try await reminderService.saveReminder(
            title: "Test Reminder",
            startDate: Date(),
            endDate: nil as Date?,
            notes: nil as String?,
            url: nil as String?,
            priority: 0,
            list: taskList,
            subHeading: nil as SubHeading?,
            tags: [],
            photos: [],
            notifications: [],
            location: nil as CLLocationCoordinate2D?,
            radius: nil as Double?,
            voiceNoteData: nil as Data?
        )
        
        let viewModel = ListDetailViewModel(context: context, taskList: taskList, reminderService: reminderService, locationService: locationservice)
        
        await viewModel.loadContent()
        
        #expect(!viewModel.reminders.isEmpty)
        #expect(viewModel.reminders.contains(where: { $0.title == "Test Reminder" }))
    }
    
    @Test("New task without list appears in InboxView")
    func testNewTaskWithoutListAppearsInInbox() async throws {
        _ = testPersistenceController.persistentContainer.viewContext
        let reminderService = ReminderService(persistenceController: testPersistenceController)
        
        let newReminder = try await reminderService.saveReminder(
            title: "Inbox Task",
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
        
        let unassignedReminders = try await reminderService.fetchUnassignedAndIncompleteReminders()
        
        #expect(!unassignedReminders.isEmpty, "Unassigned reminders should not be empty")
        #expect(unassignedReminders.contains { $0.title == "Inbox Task" }, "Unassigned reminders should contain the newly created task")
        
        try await reminderService.deleteReminder(newReminder)
    }
    
    @Test("New task with list appears in ListDetailView")
    func testNewTaskWithListAppearsInListDetail() async throws {
        let context = testPersistenceController.persistentContainer.viewContext
        let reminderService = ReminderService(persistenceController: testPersistenceController)
        
        let taskList = TaskList(context: context)
        taskList.name = "Test List"
        taskList.listID = UUID()
        try context.save()
        
        let _ = try await reminderService.saveReminder(
            title: "List Task",
            startDate: Date(),
            endDate: nil as Date?,
            notes: nil as String?,
            url: nil as String?,
            priority: 0,
            list: taskList,
            subHeading: nil as SubHeading?,
            tags: [],
            photos: [],
            notifications: [],
            location: nil as CLLocationCoordinate2D?,
            radius: nil as Double?,
            voiceNoteData: nil as Data?
        )
        
        let listReminders = try await reminderService.getRemindersForList(taskList)
        
        #expect(!listReminders.isEmpty)
        #expect(listReminders.contains(where: { $0.title == "List Task" }))
    }
    
    struct TestFailure: Error {
        let message: String
        
        init(_ message: String) {
            self.message = message
        }
    }
}
