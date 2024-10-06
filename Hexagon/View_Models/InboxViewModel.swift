//
//  InboxViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 06/10/2024.
//

import SwiftUI
import Combine
import HexagonData

@MainActor
class InboxViewModel: ObservableObject {
    @Published private(set) var reminders: [Reminder] = []
    private let reminderService: ReminderService
    private var cancellables = Set<AnyCancellable>()

    init(reminderService: ReminderService) {
        self.reminderService = reminderService
        setupObservers()
        Task {
            await fetchReminders()
        }
    }

    private func setupObservers() {
        NotificationCenter.default.publisher(for: .reminderAdded)
            .sink { [weak self] _ in
                Task {
                    await self?.fetchReminders()
                }
            }
            .store(in: &cancellables)
    }

    func fetchReminders() async {
        do {
            await reminderService.debugInboxReminders()
            let fetchedReminders = try await reminderService.fetchUnassignedAndIncompleteReminders()
            print("InboxViewModel received \(fetchedReminders.count) reminders")
            self.reminders = fetchedReminders
        } catch {
            print("Error fetching reminders: \(error)")
        }
    }

    func toggleCompletion(for reminder: Reminder) async {
        do {
            try await reminderService.updateReminderCompletionStatus(reminder: reminder, isCompleted: !reminder.isCompleted)
            await fetchReminders()
        } catch {
            print("Error toggling completion: \(error)")
        }
    }
}
