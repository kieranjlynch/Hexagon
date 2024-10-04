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
    @Published private(set) var error: IdentifiableError?
    private let reminderService: ReminderService
    private var cancellables = Set<AnyCancellable>()

    init(reminderService: ReminderService) {
        self.reminderService = reminderService
        NotificationCenter.default.addObserver(self, selector: #selector(handleReminderAdded), name: .reminderAdded, object: nil)
        
        setupObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .reminderAdded, object: nil)
    }
    
    private func setupObservers() {
        reminderService.$reminders
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
            let fetchedReminders = try await reminderService.fetchUnassignedAndIncompleteReminders()
            self.unassignedReminders = fetchedReminders
            print("InboxViewModel updated with \(fetchedReminders.count) reminders")
        } catch {
            setError(error)
            print("Error loading unassigned reminders: \(error)")
        }
    }

    func toggleCompletion(for reminder: Reminder) async {
        do {
            try await reminderService.updateReminderCompletionStatus(reminder: reminder, isCompleted: !reminder.isCompleted)
            await loadUnassignedReminders()
        } catch {
            setError(error)
        }
    }

    func deleteReminder(_ reminder: Reminder) async {
        do {
            try await reminderService.deleteReminder(reminder)
            await loadUnassignedReminders()
        } catch {
            setError(error)
        }
    }

    @objc private func handleReminderAdded() {
        Task {
            await loadUnassignedReminders()
        }
    }

    func setError(_ error: Error) {
        self.error = IdentifiableError(error: error)
    }

    func clearError() {
        self.error = nil
    }
}
