//
//  ListItemView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 17/09/2024.
//

import SwiftUI
import CoreData
import HexagonData

struct ListItemView: View {
    let taskList: TaskList
    var onDelete: () -> Void
    @State private var showEditView = false
    @Environment(\.managedObjectContext) var context
    @EnvironmentObject var reminderService: ReminderService
    @EnvironmentObject var locationService: LocationService

    var body: some View {
        NavigationLink(
            destination: {
                let viewModel = ListDetailViewModel(context: context, taskList: taskList, reminderService: reminderService, locationService: locationService)
                ListDetailView(viewModel: viewModel)
                    .environmentObject(reminderService)
                    .environmentObject(locationService)
            }
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
