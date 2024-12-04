//
//  ReminderDropDelegate.swift
//  Hexagon
//
//  Created by Kieran Lynch on 22/11/2024.
//


import UniformTypeIdentifiers
import os
import SwiftUI

class ReminderDropDelegate: DropDelegate {
    let currentSubHeading: SubHeading?
    let dragStateManager: DragStateManager
    let viewModel: ListDetailViewModel
    let filteredReminders: [Reminder]

    private let reminderHeight: CGFloat = 60
    private var scrollViewHeight: CGFloat = UIScreen.main.bounds.height

    init(currentSubHeading: SubHeading?, dragStateManager: DragStateManager, listViewModel: ListDetailViewModel, filteredReminders: [Reminder]) {
        self.currentSubHeading = currentSubHeading
        self.dragStateManager = dragStateManager
        self.viewModel = listViewModel
        self.filteredReminders = filteredReminders
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let item = dragStateManager.draggingListItem else { return false }
        let targetIndex = calculateDropIndex(at: info.location)
        viewModel.moveItem(
            item,
            toIndex: targetIndex,
            underSubHeading: currentSubHeading
        )
        dragStateManager.endDragging()

        return true
    }

    func dropEntered(info: DropInfo) {
        scrollViewHeight = info.location.y + reminderHeight * CGFloat(filteredReminders.count)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func validateDrop(info: DropInfo) -> Bool {
        guard let item = dragStateManager.draggingListItem else { return false }
        return item.type == .reminder
    }

    func dropExited(info: DropInfo) {}

    func calculateDropIndex(at location: CGPoint) -> Int {
        guard !filteredReminders.isEmpty else { return 0 }
        let sectionHeight = CGFloat(filteredReminders.count) * reminderHeight
        let percentage = max(0, min(location.y, sectionHeight)) / sectionHeight
        let rawIndex = Double(filteredReminders.count) * percentage
        let targetIndex = Int(round(rawIndex))
        let finalIndex = max(0, min(targetIndex, filteredReminders.count))
        return finalIndex
    }
}

struct SubheadingDropDelegate: DropDelegate {
    let item: SubHeading
    let listViewModel: ListDetailViewModel
    @Binding var isTargeted: Bool
    let dragStateManager: DragStateManager

    func dropEntered(info: DropInfo) {
        isTargeted = true
    }

    func dropExited(info: DropInfo) {
        isTargeted = false
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let draggingItem = dragStateManager.draggingListItem else { return false }

        listViewModel.moveItem(draggingItem, toIndex: 0, underSubHeading: item)
        dragStateManager.endDragging()
        isTargeted = false
        return true
    }
}
