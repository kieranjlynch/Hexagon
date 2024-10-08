//
//  ListDetailView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers
import HexagonData

struct ListDetailView: View {
    @Environment(\.managedObjectContext) var context
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var reminderService: ReminderService
    @Binding var selectedListID: NSManagedObjectID?
    @StateObject var viewModel: ListDetailViewModel
    @EnvironmentObject var locationService: LocationService
    @State private var selectedReminder: Reminder?
    @State private var refreshID = UUID()
    @State private var isPerformingDrop = false
    @State private var dropFeedback: IdentifiableError?
    @State private var showAddReminderView = false
    @State private var showAddSubHeadingView = false
    @State private var selectedIndex: Int = 0
    @State private var showSwipeableDetailView = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    unassignedRemindersSection
                    subheadingsSection
                }
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.listSymbol)
                            .foregroundColor(Color(UIColor.color(data: viewModel.taskList.colorData ?? Data()) ?? .gray))
                        Text(viewModel.taskList.name ?? "Unnamed List")
                            .font(.headline)
                    }
                }
            }
            .task {
                await viewModel.loadContent()
            }
            .onChange(of: viewModel.reminders) {
                handleReminderChange()
            }
            .fullScreenCover(isPresented: $showSwipeableDetailView) {
                SwipeableTaskDetailViewWrapper(
                    reminders: $viewModel.reminders,
                    currentIndex: $selectedIndex
                )
                .environmentObject(reminderService)
            }
            .overlay(alignment: .bottomTrailing) {
                floatingActionButton
            }
            .alert(item: $viewModel.error) { identifiableError in
                Alert(
                    title: Text("Error"),
                    message: Text(identifiableError.message)
                )
            }
        }
    }
    
    private var unassignedRemindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.reminders.filter { $0.subHeading == nil }, id: \.self) { reminder in
                TaskCardView(
                    reminder: reminder,
                    onTap: {
                        if let index = viewModel.reminders.firstIndex(of: reminder) {
                            selectedIndex = index
                            selectedReminder = reminder
                            showSwipeableDetailView = true
                        }
                    },
                    onToggleCompletion: {
                        Task {
                            await viewModel.toggleCompletion(reminder)
                        }
                    },
                    selectedDate: Date(),
                    selectedDuration: 60.0
                )
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                .draggable(reminder)
            }
            .padding(.top, 8)
        }
    }
    
    private var subheadingsSection: some View {
        ForEach(viewModel.subHeadings, id: \.objectID) { subHeading in
            SubheadingSection(subHeading: subHeading, viewModel: viewModel)
        }
    }
    
    private var floatingActionButton: some View {
        FloatingActionButton(
            appSettings: AppSettings(),
            showTip: .constant(false),
            tip: EmptyTip(),
            menuItems: [.addSubHeading, .addReminder]
        ) { selectedItem in
            switch selectedItem {
            case .addReminder:
                showAddReminderView = true
                
            case .addSubHeading:
                showAddSubHeadingView = true
                
            default:
                break
            }
        }
        .padding([.trailing, .bottom], 16)
        .sheet(isPresented: $showAddReminderView) {
            AddReminderView()
                .environmentObject(reminderService)
                .environmentObject(locationService)
        }
        .sheet(isPresented: $showAddSubHeadingView) {
            AddSubHeadingView(
                taskList: viewModel.taskList,
                onSave: { _ in
                    Task {
                        await viewModel.loadContent()
                    }
                },
                context: context
            )
            .environmentObject(reminderService)
        }
    }
    
    private func handleReminderChange() {
        print("Reminders updated in ListDetailView: \(viewModel.reminders.count)")
    }
}
