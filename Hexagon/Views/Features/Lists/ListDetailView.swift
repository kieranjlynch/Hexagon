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
    @State var isDragging: Bool = false
    
    var body: some View {
        let emptyDropView: some View = Image(systemName: "arrow.down.app")
            .padding(.vertical, 10)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, maxHeight: 30)
            .background(.gray)
            .opacity(0.3)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 8
                )
            )
            .padding(.horizontal, 10)
        
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
//                    unassignedRemindersSection
//                    subheadingsSection
                    
                    //unassigned
                    
                    let unassigned = viewModel.reminders.filter { $0.subHeading == nil }
                    if unassigned.count == 0 && viewModel.isDragging {
                        emptyDropView
                            .onDrop(of: [UTType.hexagonReminder], delegate: DropViewDelegate(viewModel: viewModel, item: nil, items: $viewModel.reminders, draggedItem: $dragging, subHeading: nil))
                    }
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
                            .onDrag({
                                self.viewModel.isDragging = true
                                self.dragging = reminder
                                return NSItemProvider(object: reminder)
                            })
                            .onDrop(of: [UTType.hexagonReminder], delegate: DropViewDelegate(viewModel: viewModel, item: reminder, items: $viewModel.reminders, draggedItem: $dragging, subHeading: nil))
                        }
                        
                    // sectioned
                        ForEach(viewModel.subHeadings, id: \.objectID) { subHeading in
                            Section(header: SubheadingHeader(subHeading: subHeading, viewModel: viewModel)) {
                                let sectionItems = viewModel.reminders.filter { $0.subHeading == subHeading }
                                if sectionItems.count == 0 && viewModel.isDragging{
                                    emptyDropView
                                        .onDrop(of: [UTType.hexagonReminder], delegate: DropViewDelegate(viewModel: viewModel, item: nil, items: $viewModel.reminders, draggedItem: $dragging, subHeading: subHeading))
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
                                    .onDrag({
                                        self.viewModel.isDragging = true
                                        self.dragging = reminder
                                        return NSItemProvider(object: reminder)
                                    })
                                    .listRowSeparator(.hidden)
                                    .background(Color(UIColor.systemBackground))
                                    .cornerRadius(8)
                                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    .onDrop(of: [UTType.hexagonReminder], delegate: DropViewDelegate(viewModel: viewModel, item: reminder, items: $viewModel.reminders, draggedItem: $dragging, subHeading: subHeading))
                                    
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        
                    .frame( maxWidth: .infinity)
                    .edgesIgnoringSafeArea(.horizontal)
                    .listStyle(PlainListStyle())
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
            }
            .padding(.top, 8)
        }
    }
    
    private var subheadingsSection: some View {
        ForEach(viewModel.subHeadings, id: \.objectID) { subHeading in
            SubheadingSection(subHeading: subHeading, viewModel: viewModel, dragging: dragging, isTarget: .constant(false))
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


struct DropViewDelegate: DropDelegate {
    let viewModel: ListDetailViewModel
//    @Binding var isPerformingDrop: Bool
//    @Binding var dropFeedback: IdentifiableError?
    let item : Reminder?
    @Binding var items : [Reminder]
    @Binding var draggedItem : Reminder?
    let subHeading: SubHeading?
    
    func dropEntered(info: DropInfo) {
        print(info)
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
        viewModel.isDragging = false
        guard let itemProvider = info.itemProviders(for: [UTType.hexagonReminder]).first else {
            return false
        }
        
//        isPerformingDrop = true
        
        Task {
            guard let itemToMove = draggedItem else { return }
            let success = await viewModel.handleDrop(reminders: [itemToMove], to: subHeading)
            if !success {
//                dropFeedback = IdentifiableError(message: "Failed to move reminder")
//                isPerformingDrop = false
                return
            }
//            isPerformingDrop = false
        }
        
        return true
    }
}
