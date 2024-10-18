//
//  SwipeableTaskDetailViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 20/09/2024.
//

import SwiftUI
import HexagonData
import Combine

@MainActor
class SwipeableTaskDetailViewModel: ObservableObject {
    @Published var reminders: [Reminder]
    @Published var lastUpdatedIndex: Int?

    private var cancellables = Set<AnyCancellable>()
    
    init(reminders: [Reminder]) {
        self.reminders = reminders
        
        $reminders
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Async/Await functions

    func deleteReminder(at index: Int, reminderService: ReminderService) async throws {
        guard index < reminders.count else { return }
        let reminderToDelete = reminders[index]
        
        try await reminderService.deleteReminder(reminderToDelete)
        reminders.remove(at: index)
        objectWillChange.send()
    }
    
    func updateReminder(at index: Int, with updatedReminder: Reminder, tags: [String], photos: [UIImage]) {
        guard index < reminders.count else { return }
        reminders[index] = updatedReminder
        lastUpdatedIndex = index
        objectWillChange.send()
    }
}
