//
//  ReminderListContent.swift
//  Hexagon
//
//  Created by Kieran Lynch on 23/10/2024.
//

import SwiftUI
import HexagonData
import DragAndDrop
import os

struct ReminderListContent: View {
    @ObservedObject var viewModel: ListDetailViewModel
    @EnvironmentObject var reminderService: ReminderService
    @Binding var currentReminderIndex: Int
    @Binding var showSwipeableTaskDetail: Bool
    let searchText: String
    let currentTokens: [ReminderToken]
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.klynch.Hexagon",
        category: "ReminderListContent"
    )
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.subHeadings) { subHeading in
                SubheadingSection(subHeading: subHeading, viewModel: viewModel)
                    .padding(.bottom, 8)
            }
            
            ForEach(viewModel.filteredReminders(for: nil, searchText: searchText, tokens: currentTokens)) { reminder in
                TaskCardView(
                    reminder: reminder,
                    viewModel: viewModel,
                    onTap: {
                        currentReminderIndex = viewModel.reminders.firstIndex(of: reminder) ?? 0
                        showSwipeableTaskDetail = true
                        logger.debug("Tapped reminder: \(reminder.title ?? "Untitled")")
                    },
                    onToggleCompletion: {
                        Task {
                            await viewModel.toggleCompletion(reminder)
                        }
                    },
                    selectedDate: Date(),
                    selectedDuration: 60.0
                )
                .padding(.vertical, 4)
                .dragable()
            }
            
            Spacer()
        }
        .dropReceiver(for: viewModel.dropReceiverForNoSubheading(), model: viewModel)
        .padding([.horizontal], 16)
        .padding(.top, 16)
    }
}
