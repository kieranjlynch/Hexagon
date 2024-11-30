//
//  ListItemView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 17/09/2024.
//

import SwiftUI
import CoreData

import TipKit

struct ListItemView: View {
    let taskList: TaskList
    @Binding var selectedListID: NSManagedObjectID?
    var onDelete: () -> Void
    @State private var showEditView = false
    @State private var showFloatingActionButtonTip = true
    @Environment(\.managedObjectContext) var context
    @StateObject private var viewModel: ListDetailViewModel
    private let floatingActionButtonTip = FloatingActionButtonTip()
    
    init(
        taskList: TaskList,
        selectedListID: Binding<NSManagedObjectID?>,
        onDelete: @escaping () -> Void,
        reminderFetchingService: ReminderFetchingService,
        reminderModificationService: ReminderModificationService,
        subheadingService: SubHeadingServiceFacade
    ) {
        self.taskList = taskList
        self._selectedListID = selectedListID
        self.onDelete = onDelete
        
        let viewModel = ViewModelFactory.createListDetailViewModel(
            taskList: taskList,
            reminderFetchingService: reminderFetchingService,
            reminderModificationService: reminderModificationService,
            subheadingService: subheadingService
        )
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
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
                .environment(\.managedObjectContext, context)
        }
    }
}

@MainActor
enum ViewModelFactory {
    private static var viewModelCache: [NSManagedObjectID: ListDetailViewModel] = [:]
    private static let lock = NSLock()
    
    static func createListDetailViewModel(
        taskList: TaskList,
        reminderFetchingService: ReminderFetchingService,
        reminderModificationService: ReminderModificationService,
        subheadingService: SubHeadingServiceFacade
    ) -> ListDetailViewModel {
        lock.lock()
        defer { lock.unlock() }
        
        if let cachedViewModel = viewModelCache[taskList.objectID] {
            return cachedViewModel
        }
    
        let performanceMonitor = DefaultPerformanceMonitor()
        
        _ = SubHeadingViewModel(
            subheadingManager: subheadingService as! SubHeadingManaging,
            performanceMonitor: performanceMonitor as any PerformanceMonitoring
        )
        
        let viewModel = ListDetailViewModel(
            taskList: taskList,
            reminderService: reminderFetchingService,
            subHeadingService: subheadingService,
            performanceMonitor: performanceMonitor as any PerformanceMonitoring
        )
        
        viewModelCache[taskList.objectID] = viewModel
        
        if viewModelCache.count > 100 {
            viewModelCache.removeAll()
        }
        
        return viewModel
    }
}
