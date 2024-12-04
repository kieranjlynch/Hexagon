//
//  SubheadingSection.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI

import CoreData
import os
import UniformTypeIdentifiers

struct SubheadingSection: View {
    let subHeading: SubHeading
    let listViewModel: ListDetailViewModel
    @ObservedObject var subheadingViewModel: SubHeadingViewModel
    let index: Int
    
    @State private var selectedReminder: Reminder?
    @State private var isTargeted = false
    @State private var isDragging = false
    @State private var dragOffset: CGFloat = 0
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fetchingService: ReminderFetchingServiceUI
    @EnvironmentObject var modificationService: ReminderModificationService
    @EnvironmentObject var tagService: TagService
    @EnvironmentObject var listService: ListService
    @EnvironmentObject var dragStateManager: DragStateManager
    
    let logger = Logger(subsystem: "com.hexagon.app", category: "SubheadingSection")
    
    private var filteredReminders: [Reminder] {
        listViewModel.reminders.filter { $0.subHeading == subHeading }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SubheadingHeader(subHeading: subHeading)
                .padding(.bottom, 4)
                .contentShape(Rectangle())
                .onDrop(
                    of: [.hexagonListItem],
                    isTargeted: Binding(
                        get: { isTargeted },
                        set: { isTargeted = $0 }
                    )
                ) { providers, location in
                    guard let item = dragStateManager.draggingListItem else { return false }
                    
                    listViewModel.moveItem(item, toIndex: 0, underSubHeading: subHeading)
                    dragStateManager.endDragging()
                    return true
                }
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.bottom, 4)
            
            VStack(spacing: 8) {
                ForEach(Array(filteredReminders.enumerated()), id: \.element.id) { reminderIndex, reminder in
                    ReminderRow(
                        reminder: reminder,
                        taskList: reminder.list ?? TaskList(),
                        viewModel: listViewModel,
                        index: reminderIndex
                    )
                    .onDrop(
                        of: [.hexagonListItem],
                        isTargeted: Binding(
                            get: { isTargeted },
                            set: { isTargeted = $0 }
                        )
                    ) { providers, location in
                        guard let item = dragStateManager.draggingListItem else { return false }
                        
                        listViewModel.moveItem(
                            item,
                            toIndex: reminderIndex,
                            underSubHeading: subHeading
                        )
                        dragStateManager.endDragging()
                        return true
                    }
                }
            }
        }
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isTargeted ? Color.accentColor.opacity(0.2) : Color.clear)
        )
        .opacity(isDragging ? 0.5 : 1.0)
        .onDrag {
            isDragging = true
            dragStateManager.startDragging(item: ListItemTransfer(from: subHeading))
            return NSItemProvider(object: ListItemTransfer(from: subHeading))
        }
    }
    
    private func calculateDropIndex(location: CGPoint) -> Int {
        let yOffset = location.y
        if filteredReminders.isEmpty {
            return 0
        }
        let reminderHeight = 44.0
        return max(0, Int(yOffset / reminderHeight))
    }
}
