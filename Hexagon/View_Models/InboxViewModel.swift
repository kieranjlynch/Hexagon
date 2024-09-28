//
//  InboxViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import HexagonData
import Combine

@MainActor
class InboxViewModel: ObservableObject {
    @Published var unassignedReminders: [Reminder] = []
    @Published var error: IdentifiableError?
    private var reminderService: ReminderService?
    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleReminderAdded), name: .reminderAdded, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .reminderAdded, object: nil)
    }

    func setReminderService(_ service: ReminderService) {
        self.reminderService = service
        service.$reminders
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.loadUnassignedReminders()
                }
            }
            .store(in: &cancellables)
    }

    func loadUnassignedReminders() async {
        do {
            guard let reminderService = reminderService else {
                self.error = IdentifiableError(error: NSError(domain: "InboxViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "ReminderService not set"]))
                return
            }
            let fetchedReminders = try await reminderService.fetchUnassignedAndIncompleteReminders()
            self.unassignedReminders = fetchedReminders
            print("InboxViewModel updated with \(fetchedReminders.count) reminders")
        } catch {
            self.error = IdentifiableError(error: error)
            print("Error loading unassigned reminders: \(error)")
        }
    }

    func toggleCompletion(for reminder: Reminder) async {
        do {
            guard let reminderService = reminderService else {
                self.error = IdentifiableError(error: NSError(domain: "InboxViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "ReminderService not set"]))
                return
            }
            try await reminderService.updateReminderCompletionStatus(reminder: reminder, isCompleted: !reminder.isCompleted)
            await loadUnassignedReminders()
        } catch {
            self.error = IdentifiableError(error: error)
        }
    }

    func deleteReminder(_ reminder: Reminder) async {
        do {
            guard let reminderService = reminderService else {
                self.error = IdentifiableError(error: NSError(domain: "InboxViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "ReminderService not set"]))
                return
            }
            try await reminderService.deleteReminder(reminder)
            await loadUnassignedReminders()
        } catch {
            self.error = IdentifiableError(error: error)
        }
    }

    @objc private func handleReminderAdded() {
        Task {
            await loadUnassignedReminders()
        }
    }
}
