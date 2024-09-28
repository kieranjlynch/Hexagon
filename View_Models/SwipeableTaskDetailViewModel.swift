//
//  SwipeableTaskDetailViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 20/09/2024.
//

import SwiftUI
import HexagonData

@MainActor
class SwipeableTaskDetailViewModel: ObservableObject {
    @Published var reminders: [Reminder]
    @Published var lastUpdatedIndex: Int?
    
    init(reminders: [Reminder]) {
        self.reminders = reminders
    }
    
    func deleteReminder(at index: Int, reminderService: ReminderService) async throws {
        let reminderToDelete = reminders[index]
        try await reminderService.deleteReminder(reminderToDelete)
        self.reminders.remove(at: index)
    }
    
    func updateReminder(at index: Int, with updatedReminder: Reminder, tags: [String], photos: [UIImage]) {
        guard index < reminders.count else { return }
        reminders[index] = updatedReminder
        lastUpdatedIndex = index
        objectWillChange.send()
    }
}
