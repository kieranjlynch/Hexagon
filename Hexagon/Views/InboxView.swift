//
//  InboxView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import CoreData
import TipKit
import HexagonData

struct InboxView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var reminderService: ReminderService
    @EnvironmentObject private var locationService: LocationService
    @State private var selectedReminder: Reminder?
    @State private var showFloatingActionButtonTip = false
    @State private var showAddReminderView = false
    @State private var showAddNewListView = false

    @StateObject private var viewModel = InboxViewModel()

    let floatingActionButtonTip: FloatingActionButtonTip = FloatingActionButtonTip()

    var body: some View {
        NavigationStack {
            List {
                if viewModel.unassignedReminders.isEmpty {
                    Text("No unassigned tasks")
                        .listRowSeparator(.hidden)
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding()
                        .accessibilityLabel(Text("No unassigned tasks"))
                        .accessibilityHint(Text("There are currently no tasks in your inbox."))
                } else {
                    ForEach(viewModel.unassignedReminders, id: \.reminderID) { reminder in
                        TaskCardView(
                            reminder: reminder,
                            onTap: {
                                selectedReminder = reminder
                            },
                            onToggleCompletion: {
                                Task {
                                    await viewModel.toggleCompletion(for: reminder)
                                }
                            },
                            selectedDate: Date(),
                            selectedDuration: 60.0
                        )
                        .listRowSeparator(.hidden)
                    }
                    .onDelete { indexSet in
                        deleteReminders(at: indexSet)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Inbox")
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .task {
                viewModel.setReminderService(reminderService)
                await viewModel.loadUnassignedReminders()
            }
            .onChange(of: viewModel.unassignedReminders) { oldValue, newValue in
                print("Unassigned reminders updated in InboxView: \(newValue.count)")
            }
            .sheet(item: $selectedReminder) { reminder in
                AddReminderView(reminder: reminder)
                    .environmentObject(reminderService)
                    .environmentObject(locationService)
                    .accessibilityLabel(Text("Add reminder view"))
                    .accessibilityHint(Text("Edit the reminder details here."))
            }
            .sheet(isPresented: $showAddReminderView) {
                AddReminderView()
                    .environmentObject(reminderService)
                    .environmentObject(locationService)
            }
            .sheet(isPresented: $showAddNewListView) {
                AddNewListView()
                    .environmentObject(reminderService)
            }
            .overlay(alignment: .bottomTrailing) {
                FloatingActionButton(
                    appSettings: appSettings,
                    showTip: $showFloatingActionButtonTip,
                    tip: floatingActionButtonTip,
                    menuItems: [.addReminder, .addNewList]
                ) { item in
                    switch item {
                    case .addReminder:
                        showAddReminderView = true
                    case .addNewList:
                        showAddNewListView = true
                    default:
                        break
                    }
                }
                .padding([.trailing, .bottom], 16)
            }
        }
        .onChange(of: showAddReminderView) {
            Task {
                await viewModel.loadUnassignedReminders()
            }
        }
        .alert(item: $viewModel.error) { identifiableError in
            Alert(title: Text("Error"), message: Text(identifiableError.error.localizedDescription))
        }
    }

    private func deleteReminders(at offsets: IndexSet) {
        Task {
            for index in offsets {
                await viewModel.deleteReminder(viewModel.unassignedReminders[index])
            }
        }
    }
}
