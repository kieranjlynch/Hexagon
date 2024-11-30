//
//  HistoryView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 30/10/2024.
//

import SwiftUI
import CoreData


struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel
    @EnvironmentObject private var fetchingService: ReminderFetchingServiceUI
    @EnvironmentObject private var modificationService: ReminderModificationService
    @EnvironmentObject private var subheadingService: SubheadingService
    @EnvironmentObject private var tagService: TagService
    @EnvironmentObject private var listService: ListService
    @EnvironmentObject private var appSettings: AppSettings
    
    init(
        context: NSManagedObjectContext,
        fetchingService: ReminderFetchingService,
        modificationService: ReminderModificationService,
        subheadingService: SubheadingService
    ) {
        let taskGrouper = DefaultTaskGrouper()
        _viewModel = StateObject(wrappedValue: HistoryViewModel(
            context: context,
            tasksFetcher: fetchingService,
            taskGrouper: taskGrouper,
            listDetailFactory: DefaultListDetailViewModelFactory()
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                switch viewModel.viewState {
                case .idle:
                    EmptyView()
                case .loaded(let state):
                    completedTasksList(state)
                case .loading, .searching:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .noResults:
                    Text("No completed tasks")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .error(let message):
                    VStack(spacing: 8) {
                        Text("Error loading history")
                            .foregroundColor(.secondary)
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                        Button("Retry") {
                            Task {
                                await viewModel.performLoad()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .results(let state):
                    completedTasksList(state)
                @unknown default:
                    fatalError()
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                            .environmentObject(appSettings)
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .task {
            viewModel.viewDidLoad()
            await viewModel.performLoad()
        }
    }
    
    private func completedTasksList(_ state: HistoryState) -> some View {
        List {
            let sortedDates = state.completedTasksByDate.keys.sorted(by: >)
            ForEach(sortedDates, id: \.self) { date in
                let reminders = state.completedTasksByDate[date] ?? []
                Section(header: Text("COMPLETED: \(DateFormatter.sharedDateFormatter.string(from: date))")) {
                    ForEach(reminders) { reminder in
                        ReminderRowWrapper(reminder: reminder)
                            .environmentObject(viewModel)
                            .environmentObject(fetchingService)
                            .environmentObject(modificationService)
                            .environmentObject(subheadingService)
                    }
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .adaptiveBackground()
        .refreshable {
            await viewModel.performLoad()
        }
    }
}
