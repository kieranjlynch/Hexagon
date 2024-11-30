//
//  ReminderRowWrapper.swift
//  Hexagon
//
//  Created by Kieran Lynch on 17/11/2024.
//

import SwiftUI

import CoreData

struct ReminderRowWrapper: View {
    let reminder: Reminder
    @EnvironmentObject private var viewModel: HistoryViewModel
    @EnvironmentObject private var appSettings: AppSettings
    @State private var currentIndex = 0
    
    var body: some View {
        NavigationLink {
            let fetchingService: any ReminderFetching = ReminderFetchingServiceUI.shared
            TaskDetailView(
                viewModel: TaskDetailViewModel(
                    reminder: reminder,
                    audioManager: DefaultAudioManager(),
                    fetchingService: fetchingService
                )
            )
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title ?? "")
                        .foregroundColor(.primary)
                    
                    if let startDate = reminder.startDate {
                        Text("Due: \(startDate, formatter: DateFormatter.sharedDateFormatter)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    if reminder.priority > 0 {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.blue)
                    }
                    if let photos = reminder.photos, photos.count > 0 {
                        Image(systemName: "paperclip")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .listRowBackground(Color.clear)
        .swipeActions(edge: .leading) {
            Button {
                Task {
                    try await viewModel.uncompleteTask(reminder)
                }
            } label: {
                Label("Uncomplete", systemImage: "arrow.uturn.backward")
            }
            .tint(.blue)
        }
        .onAppear {
            Task {
                _ = await viewModel.getListDetailViewModel(for: reminder)
            }
        }
    }
}
