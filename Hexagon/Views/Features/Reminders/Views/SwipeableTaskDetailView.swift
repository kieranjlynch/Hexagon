//  SwipeableTaskDetailView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.

import SwiftUI
import CoreData


struct SwipeableTaskDetailView: View {
    @StateObject private var viewModel: SwipeableTaskDetailViewModel
    @Binding var currentIndex: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var fetchingService: ReminderFetchingServiceUI
    @Environment(\.scenePhase) private var scenePhase
    @State private var showEditView = false
    @State private var showScheduleView = false
    @State private var showDeleteConfirmation = false
    @State private var showMoveView = false
    @State private var errorAlert: (isPresented: Bool, message: String) = (false, "")
    @State private var visibleRange: Range<Int> = 0..<0
    
    init(reminders: [Reminder], currentIndex: Binding<Int>) {
        self._currentIndex = currentIndex
        self._viewModel = StateObject(wrappedValue: SwipeableTaskDetailViewModel(reminders: reminders))
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $currentIndex) {
                ForEach(viewModel.viewState.reminders.indices, id: \.self) { index in
                    reminderDetailView(for: index)
                        .tag(index)
                        .id(viewModel.viewState.reminders[index].objectID)
                        .onAppear { updateVisibleRange(adding: index) }
                        .onDisappear { updateVisibleRange(removing: index) }
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .scrollContentBackground(.hidden)
            .adaptiveForegroundAndBackground()
            
            overlayContent
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                viewModel.cleanupMemory()
            }
        }
        .sheet(isPresented: $showEditView) {
            editReminderSheet
        }
        .sheet(isPresented: $showScheduleView) {
            scheduleReminderSheet
        }
        .sheet(isPresented: $showMoveView) {
            moveReminderSheet
        }
        .alert("Delete Reminder", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await deleteReminder()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this reminder?")
        }
        .alert("Error", isPresented: $errorAlert.isPresented) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorAlert.message)
        }
    }
    
    private func reminderDetailView(for index: Int) -> some View {
        TaskDetailView(
            viewModel: TaskDetailViewModel(
                reminder: viewModel.viewState.reminders[index],
                audioManager: DefaultAudioManager(),
                fetchingService: fetchingService
            )
        )
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    private var overlayContent: some View {
        VStack {
            closeButton
            Spacer()
            actionButton
        }
    }
    
    private var closeButton: some View {
        HStack {
            Spacer()
            Button(action: {
                withAnimation {
                    dismiss()
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .adaptiveColors()
                    .font(.title)
                    .padding()
            }
        }
    }
    
    private var actionButton: some View {
        FloatingActionButton<EmptyTip>(
            appSettings: appSettings,
            showTip: .constant(false),
            tip: EmptyTip(),
            menuItems: [.edit, .delete, .schedule, .move],
            onMenuItemSelected: { item in
                switch item {
                case .edit:
                    showEditView = true
                case .delete:
                    showDeleteConfirmation = true
                case .schedule:
                    showScheduleView = true
                case .move:
                    showMoveView = true
                default:
                    break
                }
            }
        )
        .padding([.trailing, .bottom], 16)
    }
    
    @ViewBuilder
    private var editReminderSheet: some View {
        if currentIndex < viewModel.viewState.reminders.count {
            AddReminderView(
                reminder: viewModel.viewState.reminders[currentIndex],
                persistentContainer: PersistenceController.shared.persistentContainer,
                fetchingService: ReminderFetchingServiceUI.shared,
                modificationService: ReminderModificationService.shared,
                tagService: TagService.shared,
                listService: ListService.shared
            )
            .environmentObject(ReminderFetchingServiceUI.shared)
            .environmentObject(ReminderModificationService.shared)
        }
    }
    
    @ViewBuilder
    private var scheduleReminderSheet: some View {
        if currentIndex < viewModel.viewState.reminders.count {
            TaskScheduleView(task: viewModel.viewState.reminders[currentIndex].title ?? "")
        }
    }
    
    @ViewBuilder
    private var moveReminderSheet: some View {
        if currentIndex < viewModel.viewState.reminders.count {
            MoveTaskView(
                reminder: viewModel.viewState.reminders[currentIndex],
                onMove: { destinationList in
                    Task {
                        do {
                            try await moveReminder(to: destinationList)
                        } catch {
                            errorAlert = (true, "Failed to move reminder: \(error.localizedDescription)")
                        }
                    }
                }
            )
        }
    }
    
    private func updateVisibleRange(adding index: Int) {
        let newRange = min(index - 1, 0)..<max(index + 2, viewModel.viewState.reminders.count)
        if newRange != visibleRange {
            visibleRange = newRange
            viewModel.preloadContent(for: Array(newRange))
        }
    }
    
    private func updateVisibleRange(removing index: Int) {
        if visibleRange.contains(index) {
            viewModel.cleanupContent(for: index)
        }
    }
    
    @MainActor
    private func deleteReminder() async {
        do {
            if currentIndex < viewModel.viewState.reminders.count {
                try await viewModel.deleteReminder(at: currentIndex)
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    if viewModel.viewState.reminders.isEmpty {
                        dismiss()
                    } else if currentIndex >= viewModel.viewState.reminders.count {
                        currentIndex = viewModel.viewState.reminders.count - 1
                    }
                }
            }
        } catch {
            errorAlert = (true, "Failed to delete reminder: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func moveReminder(to destinationList: TaskList) async throws {
        if currentIndex < viewModel.viewState.reminders.count {
            let reminder = viewModel.viewState.reminders[currentIndex]
            
            let result = await ReminderModificationService.shared.saveReminder(
                reminder: reminder,
                title: reminder.title ?? "",
                startDate: reminder.startDate ?? Date(),
                endDate: reminder.endDate,
                notes: reminder.notes,
                url: reminder.url,
                priority: reminder.priority,
                list: destinationList,
                subHeading: nil,
                tags: reminder.tags as? Set<ReminderTag> ?? Set(),
                photos: PhotoService.shared.getPhotos(for: reminder),
                notifications: Set(reminder.notificationsArray),
                voiceNoteData: reminder.voiceNote?.audioData,
                repeatOption: reminder.repeatOption,
                customRepeatInterval: reminder.customRepeatInterval
            )
            
            switch result {
            case .success(_):
                showMoveView = false
                dismiss()
            case .failure(let error):
                errorAlert = (true, "Failed to move reminder: \(error.localizedDescription)")
            }
        }
    }
}
