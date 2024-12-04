//
//  SubheadingView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 04/12/2024.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct SubheadingView: View {
    let subHeading: SubHeading
    let listViewModel: ListDetailViewModel
    let subheadingViewModel: SubHeadingViewModel
    let index: Int
    @Binding var dropTargetSection: UUID?
    let dragStateManager: DragStateManager
    @Binding var refreshTrigger: UUID
    
    @State private var selectedReminder: Reminder?
    @State private var isTargeted = false
    @State private var isDragging = false
    @State private var dragOffset: CGFloat = 0
    
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var fetchingService: ReminderFetchingServiceUI
    @EnvironmentObject private var modificationService: ReminderModificationService
    @EnvironmentObject private var tagService: TagService
    @EnvironmentObject private var listService: ListService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SubheadingHeader(subHeading: subHeading)
                .padding(.bottom, 4)
                .contentShape(Rectangle())
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.bottom, 4)
            
            VStack(spacing: 8) {
                let filteredTasks = listViewModel.filteredReminders(
                    for: subHeading,
                    searchText: "",
                    tokens: []
                ).sorted { $0.order < $1.order }
                
                ForEach(Array(filteredTasks.enumerated()), id: \.element.id) { reminderIndex, reminder in
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
                        refreshTrigger = UUID()
                        return true
                    }
                }
            }
        }
        .padding(.horizontal)
        .id(refreshTrigger)
        .background(backgroundView)
        .overlay(overlayView)
        .animation(.easeInOut(duration: 0.2), value: dropTargetSection)
        .onDrop(of: [.hexagonListItem], isTargeted: createTargetBinding()) { providers, location in
            handleDrop(location: location)
        }
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(dropTargetSection == subHeading.subheadingID ? Color.accentColor.opacity(0.15) : Color.clear)
    }
    
    private var overlayView: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(dropTargetSection == subHeading.subheadingID ? Color.accentColor : Color.clear, lineWidth: 2)
    }
    
    private func createTargetBinding() -> Binding<Bool> {
        Binding(
            get: { dropTargetSection == subHeading.subheadingID },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    dropTargetSection = newValue ? subHeading.subheadingID : nil
                }
            }
        )
    }
    
    private func handleDrop(location: CGPoint) -> Bool {
        guard let item = dragStateManager.draggingListItem else { return false }
        let targetIndex = calculateDropIndex(at: location)
        listViewModel.moveItem(item, toIndex: targetIndex, underSubHeading: subHeading)
        dragStateManager.endDragging()
        refreshTrigger = UUID()
        return true
    }
    
    private func calculateDropIndex(at location: CGPoint) -> Int {
        let yOffset = location.y
        let reminderHeight: CGFloat = 44
        return max(0, Int(yOffset / reminderHeight))
    }
}
