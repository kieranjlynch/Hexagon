//
//  SubheadingSection.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers
import HexagonData

public struct SubheadingSection: View {
    let subHeading: SubHeading
    @ObservedObject var viewModel: ListDetailViewModel
    @State private var selectedReminder: Reminder?
    @State private var isPerformingDrop = false
    @State private var dropFeedback: IdentifiableError?
    @Environment(\.managedObjectContext) var context

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SubheadingHeader(subHeading: subHeading, viewModel: viewModel)
            
            ForEach(viewModel.reminders.filter { $0.subHeading == subHeading }, id: \.objectID) { reminder in
                TaskCardView(
                    reminder: reminder,
                    onTap: {
                        selectedReminder = reminder
                    },
                    onToggleCompletion: {
                        Task {
                            await viewModel.toggleCompletion(reminder)
                        }
                    },
                    selectedDate: Date(),
                    selectedDuration: 60.0
                )
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                .draggable(reminder)
            }
        }
        .padding(.vertical, 8)
        .dropDestination(for: Reminder.self) { reminders, _ in
            Task {
                isPerformingDrop = true
                for reminder in reminders {
                    let success = await viewModel.handleDrop(reminders: [reminder], to: subHeading)
                    if !success {
                        dropFeedback = IdentifiableError(message: "Failed to move reminder")
                        isPerformingDrop = false
                        return
                    }
                }
                isPerformingDrop = false
                dropFeedback = IdentifiableError(message: "Reminder(s) moved successfully")
            }
            return true
        }
        .overlay {
            if isPerformingDrop {
                ProgressView()
                    .scaleEffect(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4))
            }
        }
        .alert(item: $dropFeedback) { feedback in
            Alert(title: Text("Drop Result"), message: Text(feedback.message))
        }
        .sheet(item: $selectedReminder) { reminder in
            AddReminderView(reminder: reminder)
                .environmentObject(viewModel.reminderService)
                .environmentObject(viewModel.locationService)
        }
    }
}
