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
//    @State var draggedItem : Reminder?
    @State private var isPerformingDrop = false
    @State private var dropFeedback: IdentifiableError?
    @State private var dropDelegate: DropViewDelegate?
    @Environment(\.managedObjectContext) var context
    
    @State var dragging: Reminder?
    @Binding var isTarget: Bool
    
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
                    .onDrag({
                        print("$£$££$")
                        self.dragging = reminder
                        return NSItemProvider(object: reminder)
                    })
//                    .onDrop(of: [UTType.hexagonReminder], delegate: DropViewDelegate(viewModel: viewModel, item: reminder, items: $viewModel.reminders, draggedItem: $dragging, subHeading: subHeading))
                }
        }
        .padding(.vertical, 8)
      
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
