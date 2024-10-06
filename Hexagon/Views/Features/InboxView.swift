//
//  InboxView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 06/10/2024.
//

import SwiftUI
import HexagonData

struct InboxView: View {
    @StateObject private var viewModel: InboxViewModel
    @EnvironmentObject private var reminderService: ReminderService
    @EnvironmentObject private var locationService: LocationService
    @State private var selectedReminder: Reminder?

    init(reminderService: ReminderService) {
        _viewModel = StateObject(wrappedValue: InboxViewModel(reminderService: reminderService))
    }

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.reminders.isEmpty {
                    ContentUnavailableView("No Tasks in Inbox", systemImage: "tray")
                } else {
                    List {
                        ForEach(viewModel.reminders) { reminder in
                            TaskCardView(
                                reminder: reminder,
                                onTap: {
                                    selectedReminder = reminder
                                },
                                onToggleCompletion: {
                                    Task {
                                        await viewModel.toggleCompletion(for: reminder)
                                    }
                                },
                                selectedDate: Date(),
                                selectedDuration: 60.0
                            )
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .adaptiveForegroundAndBackground()
                    
                }
            }
            .navigationTitle("Inbox")
        }
        .sheet(item: $selectedReminder) { reminder in
            AddReminderView(reminder: reminder)
                .environmentObject(reminderService)
                .environmentObject(locationService)
        }
    }
}
