//
//  ListDetailView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 17/09/2024.
//

import SwiftUI
import HexagonData
import CoreData
import TipKit
import os
import DragAndDrop

struct ListDetailView: View {
    @ObservedObject var viewModel: ListDetailViewModel
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject var reminderService: ReminderService
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var listService: ListService
    @StateObject private var searchViewModel = SearchViewModel()
    
    @Binding var showFloatingActionButtonTip: Bool
    
    let floatingActionButtonTip: FloatingActionButtonTip
    
    @State private var showAddReminderView = false
    @State private var showAddSubHeadingView = false
    @State private var showSwipeableTaskDetail = false
    @State private var currentReminderIndex = 0
    @State private var currentTokens = [ReminderToken]()
    @State private var availableTags: [ReminderTag] = []
    @State private var isEditing = false
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.klynch.Hexagon",
        category: "ListDetailView"
    )
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    CustomSearchBar(searchText: $searchViewModel.searchText, isEditing: $isEditing, onCommit: {
                        Task {
                            await searchViewModel.performSearch()
                        }
                    })
                    .padding([.horizontal, .top], 8)
                    
                    ReminderListContent(
                        viewModel: viewModel,
                        currentReminderIndex: $currentReminderIndex,
                        showSwipeableTaskDetail: $showSwipeableTaskDetail,
                        searchText: searchViewModel.searchText,
                        currentTokens: currentTokens
                    )
                }
                .padding(.horizontal)
                
                FloatingActionButton(
                    appSettings: appSettings,
                    showTip: $showFloatingActionButtonTip,
                    tip: floatingActionButtonTip,
                    menuItems: [.addReminder, .addSubHeading],
                    onMenuItemSelected: { item in
                        switch item {
                        case .addReminder:
                            showAddReminderView = true
                        case .addSubHeading:
                            showAddSubHeadingView = true
                        default:
                            break
                        }
                    }
                )
                .padding([.trailing, .bottom], 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    CustomNavigationTitle(taskList: viewModel.taskList)
                }
            }
            .onAppear {
                logger.info("ListDetailView appeared for list: \(viewModel.taskList.name ?? "Unknown")")
                Task {
                    await fetchData()
                }
                viewModel.setupSearchViewModel(searchViewModel)
            }
            .onChange(of: viewModel.reminders) { onRemindersChange($1) }
            .onChange(of: viewModel.subHeadings) { onSubHeadingsChange($1) }
        }
        .sheet(isPresented: $showAddReminderView) {
            AddReminderView(defaultList: viewModel.taskList)
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
                context: viewModel.context
            )
        }
        .fullScreenCover(isPresented: $showSwipeableTaskDetail) {
            SwipeableTaskDetailViewWrapper(
                reminders: $viewModel.reminders,
                currentIndex: $currentReminderIndex
            )
        }
    }
    
    private func toggleReminderCompletion(_ reminder: Reminder) {
        Task {
            await viewModel.toggleCompletion(reminder)
        }
    }
    
    private func fetchData() async {
        logger.debug("Starting to fetch reminders and subheadings")
        await viewModel.loadContent()
        await fetchTags()
        logger.debug("Finished fetching reminders and subheadings")
        logger.info("Reminders count: \(viewModel.reminders.count), SubHeadings count: \(viewModel.subHeadings.count)")
    }
    
    private func fetchTags() async {
        do {
            availableTags = try await TagService.shared.fetchTags()
        } catch {
            logger.error("Failed to fetch tags: \(error.localizedDescription)")
        }
    }
    
    private func onRemindersChange(_ newReminders: [Reminder]) {
        logger.info("Reminders updated. New count: \(newReminders.count)")
    }
    
    private func onSubHeadingsChange(_ newSubHeadings: [SubHeading]) {
        logger.info("SubHeadings updated. New count: \(newSubHeadings.count)")
    }
}
