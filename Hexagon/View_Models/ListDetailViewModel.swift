//
//  ListDetailViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 17/09/2024.
//

import Foundation
import SwiftUI
import CoreData
import HexagonData
import Combine
import os

@MainActor
public class ListDetailViewModel: ObservableObject {

    @Published var isDragging: Bool = false
    @Published public var subHeadings: [SubHeading] = []
    @Published public var reminders: [Reminder] = []
    @Published public var error: IdentifiableError?
    @Published public var listSymbol: String

    let taskList: TaskList
    let reminderService: ReminderService
    let locationService: LocationService
    private let subheadingService: SubheadingService
    public let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.klynch.Hexagon", category: "ListDetailViewModel")

    init(context: NSManagedObjectContext, taskList: TaskList, reminderService: ReminderService, locationService: LocationService) {
        self.context = context
        self.taskList = taskList
        self.reminderService = reminderService
        self.locationService = locationService
        self.subheadingService = SubheadingService(persistenceController: PersistenceController.shared)

        logger.info("ListDetailViewModel initialized for list: \(taskList.name ?? "Unknown")")

        Task {
            await self.fetchReminders()
            await self.fetchSubHeadings()
        }

        setupCombineBindings()
    }

    func addNewReminder(title: String) async {
        logger.info("Adding new reminder with title: \(title)")
        do {
            let newReminder = try await reminderService.saveReminder(
                title: title,
                in: taskList
            )
            reminders.append(newReminder)
        } catch {
            self.error = IdentifiableError(error)
        }
    }
}
