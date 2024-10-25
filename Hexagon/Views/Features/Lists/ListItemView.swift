//
//  ListItemView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 17/09/2024.
//

import SwiftUI
import CoreData
import HexagonData
import TipKit

struct ListItemView: View {
    let taskList: TaskList
    @Binding var selectedListID: NSManagedObjectID?
    var onDelete: () -> Void
    @State private var showEditView = false
    @State private var showFloatingActionButtonTip = true
    @Environment(\.managedObjectContext) var context
    @EnvironmentObject var reminderService: ReminderService
    @ObservedObject var viewModel: ListDetailViewModel
    
    private let floatingActionButtonTip = FloatingActionButtonTip()
    
    var body: some View {
        NavigationLink(
            destination: ListDetailView(
                viewModel: viewModel,
                showFloatingActionButtonTip: $showFloatingActionButtonTip,
                floatingActionButtonTip: floatingActionButtonTip
            )
        ) {
            ListCardView(
                taskList: taskList,
                onEdit: {
                    showEditView = true
                },
                onDelete: onDelete
            )
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(action: { showEditView = true }) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showEditView) {
            AddNewListView(taskList: taskList)
        }
    }
}
