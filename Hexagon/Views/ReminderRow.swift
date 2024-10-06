    //
    //  ReminderRow.swift
    //  Hexagon
    //
    //  Created by Kieran Lynch on 18/09/2024.
    //

import SwiftUI
import CoreData
import HexagonData

struct ReminderRow: View {
    let reminder: Reminder
    let taskList: TaskList
    
    @EnvironmentObject var locationService: LocationService
    @Environment(\.managedObjectContext) var context
    @EnvironmentObject var reminderService: ReminderService
    @ObservedObject var viewModel: ListDetailViewModel
    @State private var showSwipeableTaskDetail = false
    @State private var currentReminderIndex = 0
    
    var body: some View {
        TaskCardView(
            reminder: reminder,
            onTap: {
                currentReminderIndex = viewModel.reminders.firstIndex(of: reminder) ?? 0
                showSwipeableTaskDetail = true
            },
            onToggleCompletion: {
                Task {
                    await viewModel.toggleCompletion(reminder)
                }
            },
            selectedDate: Date(),
            selectedDuration: 60.0
        )
        .draggable(reminder)
        .droppableReminder(to: Optional<SubHeading>.none)
        .fullScreenCover(isPresented: $showSwipeableTaskDetail) {
            SwipeableTaskDetailView(reminders: $viewModel.reminders, currentIndex: $currentReminderIndex)
                .environmentObject(reminderService)
                .environmentObject(locationService)
        }
    }
}
