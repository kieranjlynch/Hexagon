//
//  SubheadingSection.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI
import HexagonData
import DragAndDrop

struct SubheadingSection: View {
    let subHeading: SubHeading
    @ObservedObject var viewModel: ListDetailViewModel
    @State private var selectedReminder: Reminder?
    @Environment(\.managedObjectContext) var context
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SubheadingHeader(subHeading: subHeading, viewModel: viewModel)
                .padding(.bottom, 4)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.bottom, 4)
            
            ForEach(viewModel.reminders.filter { $0.subHeading == subHeading }, id: \.objectID) { reminder in
                TaskCardView(
                    reminder: reminder,
                    viewModel: viewModel,
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
                .padding(.vertical, 4)
                .dragable(object: reminder, onDragObject: viewModel.onDraggedReminder, onDropObject: viewModel.onDroppedReminder)
            }
        }
        .dropReceiver(for: viewModel.dropReceiverForSubheading(subHeading), model: viewModel)
        .sheet(item: $selectedReminder) { reminder in
            AddReminderView(reminder: reminder)
                .environmentObject(viewModel.reminderService)
                .environmentObject(viewModel.locationService)
        }
    }
}
