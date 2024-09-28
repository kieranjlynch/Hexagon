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
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(reminderService.taskLists, id: \.self) { taskList in
                                let viewModel = ListDetailViewModel(
                                    context: context,
                                    taskList: taskList,
                                    reminderService: reminderService,
                                    locationService: locationService
                                )
                                ListItemView(
                                    taskList: taskList,
                                    selectedListID: $selectedListID,
                                    onDelete: {
                                        Task {
                                            do {
                                                try await reminderService.deleteTaskList(taskList)
                                            } catch {
                                                // Handle error
                                            }
                                        }
                                    },
                                    viewModel: viewModel
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
                    menuItems: [.addReminder, .addNewList],
                    onMenuItemSelected: { item in
                        switch item {
                        case .addReminder:
                            showAddReminderView = true
                        case .addNewList:
                            showAddNewListView = true
                        default:
                            break
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
                try await reminderService.updateTaskLists()
            }
        }
    }
}
