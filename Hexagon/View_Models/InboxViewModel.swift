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

    init(reminderService: ReminderService) {
        self.reminderService = reminderService
        Task {
            await observeReminderAddedNotifications()
            await fetchReminders()
        }
    }

    private func observeReminderAddedNotifications() async {
        for await _ in NotificationCenter.default.notifications(named: .reminderAdded) {
            await fetchReminders()
        }
    }

    func fetchReminders() async {
        do {
            let fetchedReminders = try await reminderService.fetchUnassignedAndIncompleteReminders()
            print("InboxViewModel received \(fetchedReminders.count) reminders")
            self.reminders = fetchedReminders
        } catch {
            print("Error fetching reminders: \(error.localizedDescription)")
        }
    }

    func toggleCompletion(for reminder: Reminder) async {
        do {
            try await reminderService.updateReminderCompletionStatus(reminder: reminder, isCompleted: !reminder.isCompleted)
            await fetchReminders()
        } catch {
            print("Error toggling completion: \(error.localizedDescription)")
        }
    }
}
