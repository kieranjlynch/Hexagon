//
//  DropViewDelegate.swift
//  Hexagon
//
//  Created by Darren Allen on 18/10/2024.
//

import SwiftUI
import HexagonData

struct DropViewDelegate: DropDelegate {
    let viewModel: ListDetailViewModel
    let item : Reminder?
    @Binding var items : [Reminder]
    @Binding var draggedItem : Reminder?
    let subHeading: SubHeading?
    
    func dropEntered(info: DropInfo) {
        self.viewModel.isDragging = true
        guard let draggedItem = self.draggedItem else {
            return
        }
        
        if let item = item {
            if draggedItem != item {
                let from = viewModel.reminders.firstIndex(of: draggedItem)!
                let to = viewModel.reminders.firstIndex(of: item)!
                withAnimation(.default) {
                    self.viewModel.reminders[from].subHeading = subHeading
                    self.viewModel.reminders.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
                }
            }
        } else {
            if draggedItem != item {
                let from = viewModel.reminders.firstIndex(of: draggedItem)!
                withAnimation(.default) {
                    self.viewModel.reminders[from].subHeading = subHeading
                    self.viewModel.reminders.move(fromOffsets: IndexSet(integer: from), toOffset: 0)
                }
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
            return DropProposal(operation: .move)
        }
    
    func performDrop(info: DropInfo) -> Bool {
        Task {
            await viewModel.saveDrop(reminders: self.viewModel.reminders)
        }
        print("isdragging - perform drop")
        draggedItem = nil
        self.viewModel.isDragging = false
        return true
    }
}
