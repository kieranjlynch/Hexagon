//
//  SwipeableTaskDetailView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import HexagonData

struct SwipeableTaskDetailView: View {
    @StateObject private var viewModel: SwipeableTaskDetailViewModel
    @Binding var currentIndex: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject private var appSettings: AppSettings
    @State private var showEditView = false
    @State private var showScheduleView = false
    @State private var showDeleteConfirmation = false
    @EnvironmentObject var reminderService: ReminderService
    
    init(reminders: Binding<[Reminder]>, currentIndex: Binding<Int>) {
        _viewModel = StateObject(wrappedValue: SwipeableTaskDetailViewModel(reminders: reminders.wrappedValue))
        _currentIndex = currentIndex
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $currentIndex) {
                ForEach(viewModel.reminders.indices, id: \.self) { index in
                    TaskDetailView(
                        viewModel: TaskDetailViewModel(reminder: viewModel.reminders[index], reminderService: reminderService)
                    )
                    .tag(index)
                    .id(viewModel.reminders[index].objectID)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .scrollContentBackground(.hidden)
            .adaptiveForegroundAndBackground()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .adaptiveColors()
                            .font(.title)
                            .padding()
                    }
                }
                Spacer()
                
                FloatingActionButton<EmptyTip>(
                    appSettings: appSettings,
                    showTip: .constant(false),
                    tip: EmptyTip(),
                    menuItems: [.edit, .delete, .schedule],
                    onMenuItemSelected: { item in
                        switch item {
                        case .edit:
                            showEditView = true
                        case .delete:
                            showDeleteConfirmation = true
                        case .schedule:
                            showScheduleView = true
                        default:
                            break
                        }
                    }
                )
                .padding([.trailing, .bottom], 16)
            }
        }
        .sheet(isPresented: $showEditView) {
            if currentIndex < viewModel.reminders.count {
                AddReminderView(
                    reminder: viewModel.reminders[currentIndex]
                ) { updatedReminder, updatedTags, updatedPhotos in
                    viewModel.updateReminder(at: currentIndex, with: updatedReminder, tags: updatedTags, photos: updatedPhotos)
                }
                .environmentObject(reminderService)
                .environmentObject(locationService)
            }
        }
        .sheet(isPresented: $showScheduleView) {
            if currentIndex < viewModel.reminders.count {
                TaskScheduleView(task: viewModel.reminders[currentIndex].title ?? "")
            }
        }
        .alert("Delete Reminder", isPresented: $showDeleteConfirmation, actions: {
            Button("Delete", role: .destructive) {
                Task {
                    await deleteReminder()
                }
            }
            Button("Cancel", role: .cancel) {}
        }, message: {
            Text("Are you sure you want to delete this reminder?")
        })
        .onChange(of: viewModel.lastUpdatedIndex) { oldValue, newValue in
            if let newValue {
                viewModel.reminders[newValue] = viewModel.reminders[newValue]
            }
        }
    }
    
    @MainActor
    private func deleteReminder() async {
        do {
            if currentIndex < viewModel.reminders.count {
                try await viewModel.deleteReminder(at: currentIndex, reminderService: reminderService)
                if viewModel.reminders.isEmpty {
                    dismiss()
                } else if currentIndex >= viewModel.reminders.count {
                    currentIndex = viewModel.reminders.count - 1
                }
            }
        } catch {
            print("Failed to delete reminder: \(error)")
        }
    }
}
