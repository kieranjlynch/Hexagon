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
    
    @State var dragging: Reminder?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    unassignedRemindersSection
                    subheadingsSection
                }
                .padding()
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
        VStack(spacing: 0) {
            let unassigned = viewModel.reminders.filter { $0.subHeading == nil }
            ForEach(unassigned, id: \.self) { reminder in
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
                .listRowSeparator(.hidden)
                .onDrag {
                    self.dragging = reminder
                    return NSItemProvider(object: reminder)
                } preview: {
                    TaskCardView(
                        reminder: reminder,
                        onTap: {
                            selectedReminder = reminder
                        },
                        onToggleCompletion: {
                            Task {
                                await viewModel.toggleCompletion(reminder)
                            }
                        },
                        selectedDate: Date(),
                        selectedDuration: 60.0
                    )
                    .frame(minWidth: 150, minHeight: 80)
                    .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .onDrop(of: [UTType.hexagonReminder], delegate: DropViewDelegate(viewModel: viewModel, item: reminder, items: $viewModel.reminders, draggedItem: $dragging, subHeading: nil))
            }
            EmptyDropView()
                .onDrop(of: [UTType.hexagonReminder], delegate: DropViewDelegate(viewModel: viewModel, item: nil, items: $viewModel.reminders, draggedItem: $dragging, subHeading: nil))
                .opacity((unassigned.count == 0) ? 1 : 0)
        }
    }
    
    private var subheadingsSection: some View {
        ForEach(viewModel.subHeadings, id: \.objectID) { subHeading in
            SubheadingHeader(subHeading: subHeading, viewModel: viewModel)
            let sectionItems = viewModel.reminders.filter { $0.subHeading == subHeading }
            if sectionItems.count != 0 {
                Divider()
                    .background(Color.gray.opacity(0.5))
                    .padding(.top, 4)
            }
            ForEach(sectionItems, id: \.objectID) { reminder in
                TaskCardView(
                    reminder: reminder,
                    onTap: {
                        selectedReminder = reminder
                    },
                    onToggleCompletion: {
                        Task {
                            await viewModel.toggleCompletion(reminder)
                        }
                    },
                    selectedDate: Date(),
                    selectedDuration: 60.0
                )
                .onDrag {
                    self.dragging = reminder
                    return NSItemProvider(object: reminder)
                } preview: {
                    TaskCardView(
                        reminder: reminder,
                        onTap: {
                            selectedReminder = reminder
                        },
                        onToggleCompletion: {
                            Task {
                                await viewModel.toggleCompletion(reminder)
                            }
                        },
                        selectedDate: Date(),
                        selectedDuration: 60.0
                    )
                    .frame(minWidth: 150, minHeight: 80)
                    .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                .listRowSeparator(.hidden)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                .onDrop(of: [UTType.hexagonReminder], delegate: DropViewDelegate(viewModel: viewModel, item: reminder, items: $viewModel.reminders, draggedItem: $dragging, subHeading: subHeading))

            }
            .padding(.vertical, 8)
            EmptyDropView()
                .onDrop(of: [UTType.hexagonReminder], delegate: DropViewDelegate(viewModel: viewModel, item: nil, items: $viewModel.reminders, draggedItem: $dragging, subHeading: subHeading))
                .opacity(sectionItems.count == 0 ? 1 : 0)
        }
        .sheet(item: $selectedReminder) { reminder in
            AddReminderView(reminder: reminder)
                .environmentObject(viewModel.reminderService)
                .environmentObject(viewModel.locationService)
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
}


