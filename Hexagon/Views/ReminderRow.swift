//  ReminderRow.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.

import SwiftUI
import CoreData
import os
import UniformTypeIdentifiers

struct ReminderRow: View {
    let reminder: Reminder
    let taskList: TaskList
    let viewModel: ListDetailViewModel
    let index: Int
    
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    
    @EnvironmentObject private var fetchingService: ReminderFetchingServiceUI
    @EnvironmentObject private var modificationService: ReminderModificationService
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var dragStateManager: DragStateManager
    
    @State private var currentReminderIndex = 0
    @State private var showSwipeableTaskDetail = false
    @State private var isTargeted = false
    @State private var isDragging = false
    
    private let logger = Logger(subsystem: "com.hexagon.app", category: "ReminderRow")
    
    var body: some View {
        ReminderContentView(
            reminder: reminder,
            colorScheme: colorScheme,
            toggleAction: { Task { await viewModel.toggleCompletion(reminder) }}
        )
        .modifier(ReminderRowStyle(isTargeted: isTargeted))
        .frame(height: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            if let index = viewModel.reminders.firstIndex(of: reminder) {
                currentReminderIndex = index
                showSwipeableTaskDetail = true
            }
        }
        .onDrag {
            if dragStateManager.dragState == .inactive {
                dragStateManager.startDragging(item: ListItemTransfer(from: reminder))
            }
            return NSItemProvider(object: ListItemTransfer(from: reminder))
        }
        .onDrop(
            of: [.hexagonListItem],
            isTargeted: Binding(
                get: { self.isTargeted },
                set: { newValue in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.isTargeted = newValue
                    }
                }
            )
        ) { providers, location in
            guard let item = dragStateManager.draggingListItem else { return false }
            
            let targetIndex = calculateDropIndex(at: location)
            viewModel.moveItem(item, toIndex: targetIndex, underSubHeading: reminder.subHeading)
            
            dragStateManager.endDragging()
            return true
        }
        .opacity(isDragging ? 0.5 : 1.0)
        .onChange(of: dragStateManager.dragState) { _, newValue in
            withAnimation(.easeInOut(duration: 0.2)) {
                isDragging = newValue != .inactive
            }
        }
        .fullScreenCover(isPresented: $showSwipeableTaskDetail) {
            SwipeableTaskDetailView(
                reminders: viewModel.reminders,
                currentIndex: $currentReminderIndex
            )
            .environmentObject(fetchingService)
            .environmentObject(modificationService)
        }
    }
    
    func calculateDropIndex(at location: CGPoint) -> Int {
        let reminders = viewModel.reminders
        let itemHeight: CGFloat = 44
        let dropY = location.y
        let sectionIndex = Int(dropY / itemHeight)
        let positionInSection = dropY.truncatingRemainder(dividingBy: itemHeight)
        let isInLowerHalf = positionInSection > (itemHeight / 2)
        let targetIndex = isInLowerHalf ? sectionIndex + 1 : sectionIndex
        return max(0, min(reminders.count, targetIndex))
    }
}

struct ReminderContentView: View {
    let reminder: Reminder
    let colorScheme: ColorScheme
    let toggleAction: () -> Void
    
    @State private var isCompletedLocally = false
    @State private var isVisible = true
    
    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCompletedLocally = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isVisible = false
                        }
                        toggleAction()
                    }
                }) {
                    Image(systemName: isCompletedLocally ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isCompletedLocally ? .green : .gray)
                        .animation(.easeInOut(duration: 0.2), value: isCompletedLocally)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title ?? "Untitled Task")
                        .font(.body)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .strikethrough(isCompletedLocally)
                    
                    if let dueDate = reminder.endDate {
                        Text("Due: \(DateFormatter.sharedDateFormatter.string(from: dueDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .contentShape(Rectangle())
                
                Spacer()
            }
            .padding(.leading)
            .padding(.bottom, 4)
            .transition(.opacity)
        }
    }
}

private struct ReminderRowStyle: ViewModifier {
    let isTargeted: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isTargeted ? Color.accentColor.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isTargeted ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
    }
}
