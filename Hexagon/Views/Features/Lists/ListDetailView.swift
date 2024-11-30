//  ListDetailView.swift
//  Hexagon

import SwiftUI
import TipKit
import os
import CoreData
import UniformTypeIdentifiers


struct ListDetailView: View {
    @ObservedObject var viewModel: ListDetailViewModel
    @EnvironmentObject private var dragStateManager: DragStateManager

    @StateObject private var searchViewModel: SearchViewModel
    @StateObject private var subheadingViewModel: SubHeadingViewModel

    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var reminderModificationService: ReminderModificationService
    @EnvironmentObject private var tagService: TagService
    @EnvironmentObject private var listService: ListService

    @Binding var showFloatingActionButtonTip: Bool
    let floatingActionButtonTip: FloatingActionButtonTip

    @State private var showAddReminderView = false
    @State private var showAddSubHeadingView = false
    @State private var showSwipeableTaskDetail = false
    @State private var currentReminderIndex = 0
    @State private var currentTokens = [ReminderToken]()
    @State private var searchText = ""
    @State private var isTargeted = false
    @State private var isInitializing = true
    @State private var dropTargetSection: UUID?
    @State private var refreshID = UUID()

    init(
        viewModel: ListDetailViewModel,
        showFloatingActionButtonTip: Binding<Bool>,
        floatingActionButtonTip: FloatingActionButtonTip
    ) {
        self.viewModel = viewModel
        self._showFloatingActionButtonTip = showFloatingActionButtonTip
        self.floatingActionButtonTip = floatingActionButtonTip

        let search = SearchViewModel(searchDataProvider: ReminderFetchingService.shared)
        self._searchViewModel = StateObject(wrappedValue: search)

        self._subheadingViewModel = StateObject(wrappedValue: SubHeadingViewModel(
            subheadingManager: SubheadingManager.shared,
            performanceMonitor: PerformanceMonitor()
        ))
    }

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle(viewModel.taskList.name ?? "Unnamed List")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showAddReminderView) { addReminderSheet }
                .sheet(isPresented: $showAddSubHeadingView) { addSubHeadingSheet }
                .onAppear { onAppearTasks() }
        }
    }

    private var mainContent: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    subHeadingsSection
                        .id(refreshID)

                    if !viewModel.subHeadingsArray.isEmpty {
                        NoSubheadingDropZone(
                            isTargeted: $isTargeted,
                            dragStateManager: dragStateManager,
                            viewModel: viewModel
                        )
                    }

                    mainRemindersSection
                        .id(refreshID)
                }
                .padding(.horizontal)
            }
            .refreshable {
                await viewModel.reloadRemindersState()
                refreshID = UUID()
            }
            .onDrop(of: [.hexagonListItem], isTargeted: mainDropTargeted) { providers, location in
                handleMainDrop(location: location)
            }
            .onChange(of: isTargeted) { _, newValue in
                handleTargetChange(newValue)
            }

            floatingActionButton()
        }
    }

    private var mainRemindersSection: some View {
        LazyVStack(spacing: 8) {
            let filteredTasks = viewModel.filteredReminders(
                for: nil,
                searchText: searchText,
                tokens: currentTokens
            ).sorted { $0.order < $1.order }

            ForEach(Array(filteredTasks.enumerated()), id: \.element.id) { index, reminder in
                ReminderRow(
                    reminder: reminder,
                    taskList: viewModel.taskList,
                    viewModel: viewModel,
                    index: index
                )
                .id(reminder.id)
                .frame(height: 44)
                .onDrop(
                    of: [.hexagonListItem],
                    isTargeted: Binding(
                        get: { isTargeted },
                        set: { newValue in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isTargeted = newValue
                            }
                        }
                    )
                ) { providers, location in
                    guard let item = dragStateManager.draggingListItem else { return false }
                    let dropIndex = index
                    if item.type == .reminder {
                        viewModel.moveItem(item, toIndex: dropIndex, underSubHeading: nil)
                    }
                    dragStateManager.endDragging()
                    return true
                }
            }

            Color.clear
                .frame(height: 1)
                .onDrop(
                    of: [.hexagonListItem],
                    isTargeted: $isTargeted
                ) { providers, location in
                    guard let item = dragStateManager.draggingListItem else { return false }
                    viewModel.moveItem(item, toIndex: filteredTasks.count, underSubHeading: nil)
                    dragStateManager.endDragging()
                    return true
                }
        }
    }

    private var addReminderSheet: some View {
        AddReminderView(
            defaultList: viewModel.taskList,
            persistentContainer: PersistenceController.shared.persistentContainer,
            fetchingService: ReminderFetchingServiceUI.shared,
            modificationService: reminderModificationService,
            tagService: tagService,
            listService: listService
        )
    }

    private var addSubHeadingSheet: some View {
        AddSubHeadingView(
            taskList: viewModel.taskList,
            onSave: { _ in
                Task {
                    await viewModel.reloadRemindersState()
                    refreshID = UUID()
                }
            },
            context: PersistenceController.shared.persistentContainer.viewContext
        )
    }

    private var mainDropTargeted: Binding<Bool> {
        Binding(
            get: { isTargeted },
            set: {
                isTargeted = $0
                if !$0 { dropTargetSection = nil }
            }
        )
    }

    private func handleMainDrop(location: CGPoint) -> Bool {
        guard let item = dragStateManager.draggingListItem else { return false }
        let targetIndex = calculateDropIndex(at: location)
        viewModel.moveItem(item, toIndex: targetIndex, underSubHeading: nil)
        dragStateManager.endDragging()
        refreshID = UUID()
        return true
    }

    private func handleTargetChange(_ newValue: Bool) {
        if !newValue {
            withAnimation(.easeInOut(duration: 0.2)) {
                dropTargetSection = nil
            }
        }
    }

    private var subHeadingsSection: some View {
        ForEach(Array(viewModel.subHeadingsArray.enumerated()), id: \.element.id) { index, subHeading in
            SubheadingView(
                subHeading: subHeading,
                listViewModel: viewModel,
                subheadingViewModel: subheadingViewModel,
                index: index,
                dropTargetSection: $dropTargetSection,
                dragStateManager: dragStateManager,
                refreshTrigger: $refreshID
            )
        }
    }

    private func floatingActionButton() -> some View {
        FloatingActionButton(
            appSettings: appSettings,
            showTip: $showFloatingActionButtonTip,
            tip: floatingActionButtonTip,
            menuItems: [.addReminder, .addSubHeading],
            onMenuItemSelected: handleFloatingButtonSelection
        )
        .padding([.trailing, .bottom], 16)
    }

    private func handleFloatingButtonSelection(item: FloatingActionButtonItem) {
        switch item {
        case .addReminder:
            showAddReminderView = true
        case .addSubHeading:
            showAddSubHeadingView = true
        default:
            break
        }
    }

    private func onAppearTasks() {
        viewModel.setupSearchViewModel(searchViewModel)
        if !isInitializing {
            Task {
                await viewModel.reloadRemindersState()
                refreshID = UUID()
            }
        }
        isInitializing = false
    }

    func calculateDropIndex(at location: CGPoint) -> Int {
        let yOffset = location.y
        _ = viewModel.reminders
        let reminderHeight: CGFloat = 44
        return max(0, Int(yOffset / reminderHeight))
    }
}

private struct SubheadingView: View {
    let subHeading: SubHeading
    let listViewModel: ListDetailViewModel
    let subheadingViewModel: SubHeadingViewModel
    let index: Int
    @Binding var dropTargetSection: UUID?
    let dragStateManager: DragStateManager
    @Binding var refreshTrigger: UUID

    var body: some View {
        SubheadingSection(
            subHeading: subHeading,
            listViewModel: listViewModel,
            subheadingViewModel: subheadingViewModel,
            index: index
        )
        .id(refreshTrigger)
        .background(backgroundView)
        .overlay(overlayView)
        .animation(.easeInOut(duration: 0.2), value: dropTargetSection)
        .onDrop(of: [.hexagonListItem], isTargeted: createTargetBinding()) { providers, location in
            handleDrop(location: location)
        }
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(dropTargetSection == subHeading.subheadingID ? Color.accentColor.opacity(0.15) : Color.clear)
    }

    private var overlayView: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(dropTargetSection == subHeading.subheadingID ? Color.accentColor : Color.clear, lineWidth: 2)
    }

    private func createTargetBinding() -> Binding<Bool> {
        Binding(
            get: { dropTargetSection == subHeading.subheadingID },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    dropTargetSection = newValue ? subHeading.subheadingID : nil
                }
            }
        )
    }

    private func handleDrop(location: CGPoint) -> Bool {
        guard let item = dragStateManager.draggingListItem else { return false }
        let targetIndex = calculateDropIndex(at: location)
        listViewModel.moveItem(item, toIndex: targetIndex, underSubHeading: subHeading)
        dragStateManager.endDragging()
        refreshTrigger = UUID()
        return true
    }

    private func calculateDropIndex(at location: CGPoint) -> Int {
        let yOffset = location.y
        let reminderHeight: CGFloat = 44
        return max(0, Int(yOffset / reminderHeight))
    }
}

extension View {
    func withRequiredEnvironmentObjects() -> some View {
        self
            .environmentObject(ReminderModificationService.shared)
            .environmentObject(TagService.shared)
            .environmentObject(ListService.shared)
            .environmentObject(ReminderFetchingServiceUI.shared)
            .environmentObject(DragStateManager.shared)
    }
}
