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
import UIKit

@testable import Hexagon

@MainActor
@Suite("HexagonTests")
struct HexagonTests {
    
    let testPersistenceController: PersistenceController
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
        
        let updatedReminders = try await reminderService.fetchReminders()
        guard let updatedReminder = updatedReminders.first(where: { $0.title == title }) else {
            throw TestFailure("Updated reminder not found")
        }
        
        #expect(updatedReminder.isCompleted == true)
    }
    
    @Test("SubheadingService - Save and Fetch Subheading")
    func testSaveAndFetchSubheading() async throws {
        let context = testPersistenceController.persistentContainer.viewContext
        
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
        
        let taskList = TaskList(context: context)
        taskList.name = "Test List"
        taskList.listID = UUID()
        try context.save()
        
        _ = try await reminderService.saveReminder(
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
        
        let viewModel = ListDetailViewModel(context: context, taskList: taskList, reminderService: reminderService, locationService: locationService)
        
        await viewModel.loadContent()
        
        #expect(!viewModel.reminders.isEmpty)
        #expect(viewModel.reminders.contains(where: { $0.title == "Test Reminder" }))
    }
    
    @Test("New task without list appears in InboxView")
    func testNewTaskWithoutListAppearsInInbox() async throws {
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
    
    @Test("TagService - Create and Fetch Tags")
    func testCreateAndFetchTags() async throws {
        let tagName = "TestTag"
        let createdTag = try await tagService.createTag(name: tagName)
        
        let fetchedTags = try await tagService.fetchTags()
        
        #expect(!fetchedTags.isEmpty)
        #expect(fetchedTags.contains(where: { $0.name == tagName }))
        #expect(createdTag.name == tagName)
    }
    
    @Test("ListService - Create and Fetch Lists")
    func testCreateAndFetchLists() async throws {
        let listName = "TestList"
        let _ = try await listService.saveTaskList(name: listName, color: .red, symbol: "list.bullet")
        
        let fetchedLists = try await listService.updateTaskLists()
        
        #expect(!fetchedLists.isEmpty)
        #expect(fetchedLists.contains(where: { $0.name == listName }))
    }
    
    @Test("ReminderService - Delete Reminder")
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
    
    @Test("ReminderService - Update Reminder")
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
            tags: reminder.tags as? Set<HexagonData.Tag> ?? [],
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
    
    @Test("AddReminderViewModel - Add Tags to Reminder")
    func testAddTagsToReminder() async throws {
        let viewModel = AddReminderViewModel()
        viewModel.reminderService = reminderService
        viewModel.title = "Tagged Reminder"
        
        let tag1 = try await tagService.createTag(name: "Tag1")
        let tag2 = try await tagService.createTag(name: "Tag2")
        
        viewModel.selectedTags.insert(tag1)
        viewModel.selectedTags.insert(tag2)
        
        let (savedReminder, _, _) = try await viewModel.saveReminder()
        
        #expect(savedReminder.tags?.count == 2)
        #expect(savedReminder.tags?.contains(tag1) == true)
        #expect(savedReminder.tags?.contains(tag2) == true)
    }
    
    @Test("LocationService - Save and Fetch Locations")
    func testSaveAndFetchLocations() async throws {
        let locationName = "Test Location"
        let latitude = 40.7128
        let longitude = -74.0060
        
        let savedLocation = try await locationService.saveLocation(name: locationName, latitude: latitude, longitude: longitude)
        
        let fetchedLocations = try await locationService.fetchLocations()
        
        #expect(!fetchedLocations.isEmpty)
        #expect(fetchedLocations.contains(where: { $0.name == locationName }))
        #expect(savedLocation.latitude == latitude)
        #expect(savedLocation.longitude == longitude)
    }
    
    @Test("SubheadingService - Update Subheading")
    func testUpdateSubheading() async throws {
        let context = testPersistenceController.persistentContainer.viewContext
        let taskList = TaskList(context: context)
        taskList.name = "Test List"
        taskList.listID = UUID()
        try context.save()
        
        let subheading = try await subheadingService.saveSubHeading(title: "Original", taskList: taskList)
        
        try await subheadingService.updateSubHeading(subheading, title: "Updated")
        
        let fetchedSubheadings = try await subheadingService.fetchSubHeadings(for: taskList)
        
        #expect(fetchedSubheadings.contains(where: { $0.title == "Updated" }))
        #expect(!fetchedSubheadings.contains(where: { $0.title == "Original" }))
    }
    
    @Test("SubheadingService - Delete Subheading")
    func testDeleteSubheading() async throws {
        let context = testPersistenceController.persistentContainer.viewContext
        let taskList = TaskList(context: context)
        taskList.name = "Test List"
        taskList.listID = UUID()
        try context.save()
        
        let subheading = try await subheadingService.saveSubHeading(title: "Delete Me", taskList: taskList)
        
        try await subheadingService.deleteSubHeading(subheading)
        
        let fetchedSubheadings = try await subheadingService.fetchSubHeadings(for: taskList)
        
        #expect(!fetchedSubheadings.contains(where: { $0.title == "Delete Me" }))
    }
    
    @Test("TimelineViewModel - Load Tasks for Specific Date")
    func testLoadTasksForSpecificDate() async throws {
        let viewModel = TimelineViewModel(reminderService: reminderService, listService: listService)
        
        let specificDate = Date()
        _ = try await reminderService.saveReminder(
            title: "Timeline Task",
            startDate: specificDate,
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
        
        await viewModel.loadTasks()
        
        let tasksForDate = viewModel.tasksForDate(specificDate)
        
        #expect(!tasksForDate.isEmpty)
        #expect(tasksForDate.contains(where: { $0.title == "Timeline Task" }))
    }
    
    @Test("SearchViewModel - Perform Search with Filters")
    func testPerformSearchWithFilters() async throws {
        let viewModel = SearchViewModel()
        viewModel.setup(reminderService: reminderService, viewContext: testPersistenceController.persistentContainer.viewContext)
        
        _ = try await reminderService.saveReminder(
            title: "High Priority Task",
            startDate: Date(),
            endDate: nil,
            notes: nil,
            url: nil,
            priority: 3,
            list: nil,
            subHeading: nil,
            tags: [],
            photos: [],
            notifications: [],
            location: nil,
            radius: nil,
            voiceNoteData: nil
        )
        
        viewModel.filterItems = [FilterItem(criteria: .priority, value: "3")]
        
        await viewModel.performSearch()
        
        #expect(!viewModel.searchResults.isEmpty)
        #expect(viewModel.searchResults.contains(where: { $0.title == "High Priority Task" }))
    }
    
    @Test("ReminderService - Fetch Reminders by Date Range")
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
    
    @Test("PhotoService - Save and Retrieve Photos")
    func testSaveAndRetrievePhotos() async throws {
        let photoService = PhotoService(persistenceController: testPersistenceController)
        let testImage = UIImage(systemName: "star.fill")!
        
        print("Test image size: \(testImage.size)")
        
        let reminder = try await reminderService.saveReminder(
            title: "Photo Test",
            startDate: Date(),
            endDate: nil,
            notes: nil,
            url: nil,
            priority: 0,
            list: nil,
            subHeading: nil,
            tags: [],
            photos: [testImage],
            notifications: [],
            location: nil,
            radius: nil,
            voiceNoteData: nil
        )
        
        print("Reminder saved. ObjectID: \(reminder.objectID)")
        print("Saved reminder isInInbox: \(reminder.isInInbox)")
        
        let fetchedReminder = try reminderService.getReminder(withID: reminder.objectID)
        
        print("Fetched reminder. ObjectID: \(fetchedReminder.objectID)")
        print("Fetched reminder isInInbox: \(fetchedReminder.isInInbox)")
        print("Fetched reminder photos count: \(fetchedReminder.photos?.count ?? 0)")
        
        if let photos = fetchedReminder.photos as? Set<ReminderPhoto> {
            for photo in photos {
                print("Photo data size: \(photo.photoData?.count ?? 0) bytes")
            }
        }
        
        let retrievedPhotos = photoService.getPhotos(for: fetchedReminder)
        
        print("Retrieved photos count: \(retrievedPhotos.count)")
        
        #expect(retrievedPhotos.count == 1, "Expected 1 photo, but got \(retrievedPhotos.count)")
        
        guard let retrievedImage = retrievedPhotos.first else {
            throw TestFailure("No image retrieved")
        }
        
        print("Retrieved image size: \(retrievedImage.size)")
        print("Test image size: \(testImage.size)")
        
        // Compare image sizes
        let sizeThreshold: CGFloat = 1.0  // Allow for small differences due to rounding
        #expect(abs(retrievedImage.size.width - testImage.size.width) <= sizeThreshold &&
                abs(retrievedImage.size.height - testImage.size.height) <= sizeThreshold,
                "Expected size close to \(testImage.size), but got \(retrievedImage.size)")
        
        // Compare image data
        let originalImageData = testImage.pngData()
        let retrievedImageData = retrievedImage.pngData()
        
        print("Original image data size: \(originalImageData?.count ?? 0) bytes")
        print("Retrieved image data size: \(retrievedImageData?.count ?? 0) bytes")
        
        #expect(originalImageData == retrievedImageData, "Image data doesn't match")
    }
    
    @Test("ListService - Update List Properties")
    func testUpdateListProperties() async throws {
        let listName = "Update Test List"
        try await listService.saveTaskList(name: listName, color: .red, symbol: "list.bullet")
        
        let initialLists = try await listService.updateTaskLists()
        guard let taskList = initialLists.first(where: { $0.name == listName }) else {
            throw TestFailure("Failed to create initial TaskList")
        }
        
        try await listService.updateTaskList(taskList, name: "Updated List", color: .blue, symbol: "star")
        
        let updatedLists = try await listService.updateTaskLists()
        guard let updatedList = updatedLists.first(where: { $0.listID == taskList.listID }) else {
            throw TestFailure("Updated list not found")
        }
        
        #expect(updatedList.name == "Updated List")
        #expect(updatedList.symbol == "star")
    }
    
    @Test("InboxViewModel - Fetch Unassigned Reminders")
    func testFetchUnassignedReminders() async throws {
        let viewModel = InboxViewModel(reminderService: reminderService)
        
        try await listService.saveTaskList(name: "Test List", color: .red, symbol: "list.bullet")
        let lists = try await listService.updateTaskLists()
        guard let taskList = lists.first(where: { $0.name == "Test List" }) else {
            throw TestFailure("Failed to create test TaskList")
        }
        
        let _ = try await reminderService.saveReminder(
            title: "Assigned Reminder",
            startDate: Date(),
            endDate: nil,
            notes: nil,
            url: nil,
            priority: 0,
            list: taskList,
            subHeading: nil,
            tags: [],
            photos: [],
            notifications: [],
            location: nil,
            radius: nil,
            voiceNoteData: nil
        )
        
        let _ = try await reminderService.saveReminder(
            title: "Unassigned Reminder",
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
        
        await viewModel.fetchReminders()
        
        #expect(viewModel.reminders.count == 1)
        #expect(viewModel.reminders.first?.title == "Unassigned Reminder")
    }
    
    @Test("SwipeableTaskDetailViewModel - Update Reminder in Swipeable View")
    func testUpdateReminderInSwipeableView() async throws {
        let reminder1 = try await reminderService.saveReminder(
            title: "Swipeable Reminder 1",
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
        
        let reminder2 = try await reminderService.saveReminder(
            title: "Swipeable Reminder 2",
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
        
        let viewModel = SwipeableTaskDetailViewModel(reminders: [reminder1, reminder2])
        
        let updatedReminder = reminder1
        updatedReminder.title = "Updated Swipeable Reminder"
        
        viewModel.updateReminder(at: 0, with: updatedReminder, tags: [], photos: [])
        
        #expect(viewModel.reminders[0].title == "Updated Swipeable Reminder")
        #expect(viewModel.lastUpdatedIndex == 0)
    }
}

struct TestFailure: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}

