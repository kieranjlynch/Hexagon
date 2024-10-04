//
//  ListsView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import CoreData
import TipKit
import HexagonData

struct ListsView: View {
    @Environment(\.managedObjectContext) var context
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @EnvironmentObject private var listService: ListService
    @EnvironmentObject private var appSettings: AppSettings
    @Binding var selectedListID: NSManagedObjectID?
    @Binding var showFloatingActionButtonTip: Bool
    @Binding var showInboxTip: Bool
    @EnvironmentObject var reminderService: ReminderService
    @EnvironmentObject var locationService: LocationService
    let floatingActionButtonTip: FloatingActionButtonTip
    let inboxTip: InboxTip
    
    @State private var showAddReminderView = false
    @State private var showAddNewListView = false
    @State private var showEditListView = false
    @State private var showScheduleView = false
    @State private var selectedTaskList: TaskList?

    // Function to create ViewModel for each taskList
    private func viewModelForTaskList(_ taskList: TaskList) -> ListDetailViewModel {
        return ListDetailViewModel(
            context: context,
            taskList: taskList,
            reminderService: reminderService,
            locationService: locationService
        )
    }

    // Async function to handle deletion of task lists
    private func deleteTaskList(_ taskList: TaskList) {
        Task {
            do {
                try await listService.deleteTaskList(taskList)
            } catch {
                // Handle error if necessary
            }
        }
    }
    
    // Helper function to fetch TaskList based on selectedListID
    private func fetchSelectedTaskList() -> TaskList? {
        guard let selectedListID = selectedListID else { return nil }
        return listService.taskLists.first { $0.objectID == selectedListID }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(listService.taskLists, id: \.self) { taskList in
                                ListItemView(
                                    taskList: taskList,
                                    selectedListID: $selectedListID,
                                    onDelete: {
                                        deleteTaskList(taskList)
                                    },
                                    viewModel: viewModelForTaskList(taskList)
                                )
                            }
                        }
                        .padding()
                    }
                    Spacer()
                }
                
                FloatingActionButton(
                    appSettings: appSettings,
                    showTip: $showFloatingActionButtonTip,
                    tip: floatingActionButtonTip,
                    menuItems: [.addReminder, .addNewList, .addSubHeading, .edit, .delete, .schedule],
                    onMenuItemSelected: { item in
                        switch item {
                        case .addReminder:
                            showAddReminderView = true
                        case .addNewList:
                            showAddNewListView = true
                        case .addSubHeading:
                            if let taskList = fetchSelectedTaskList() {
                                Task {
                                    do {
                                        try await listService.updateTaskList(taskList, name: taskList.name ?? "task list", color: .blue, symbol: "text.badge.plus")
                                      
                                    } catch {
                                        // Handle error if necessary
                                    }
                                }
                            } else {
                                // Handle case when no list is selected
                            }
                        case .edit:
                            if let taskList = fetchSelectedTaskList() {
                                selectedTaskList = taskList
                                showEditListView = true
                            }
                        case .delete:
                            if let taskList = fetchSelectedTaskList() {
                                deleteTaskList(taskList)
                            } else {
                                // Handle case when no list is selected
                            }
                        case .schedule:
                            if let taskList = fetchSelectedTaskList() {
                                selectedTaskList = taskList
                                showScheduleView = true
                            }
                        }
                    }
                )
                
                if showInboxTip {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            TipView(inboxTip)
                                .frame(maxWidth: 250)
                                .padding()
                                .offset(x: UIHelper.inboxTipXOffset(for: dynamicTypeSize), y: UIHelper.inboxTipOffset(for: dynamicTypeSize))
                                .transition(.opacity)
                        }
                    }
                }
            }
            .navigationTitle("Lists")
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .toolbarBackground(Color(colorScheme == .dark ? .black : .white), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
        }
        .sheet(isPresented: $showAddReminderView) {
            AddReminderView()
                .environmentObject(reminderService)
                .environmentObject(locationService)
        }
        .sheet(isPresented: $showAddNewListView) {
            AddNewListView()
        }
        .onAppear {
            Task {
                try await listService.updateTaskLists()
            }
        }
    }
}
