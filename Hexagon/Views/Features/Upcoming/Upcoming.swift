//
//  UpcomingView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 27/09/2024.
//

import SwiftUI


struct UpcomingView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var viewModel: UpcomingViewModel
    
    init(fetchingService: ReminderFetchingService, listService: ListService) {
        _viewModel = StateObject(wrappedValue: UpcomingViewModel(
            dataProvider: fetchingService,
            calendarService: CalendarService.shared,
            configuration: .default
        ))
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Upcoming")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            SettingsView()
                                .environmentObject(appSettings)
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
                .onChange(of: Task.isCancelled) { oldValue, newValue in
                    Task {
                        await viewModel.refreshData()
                    }
                }
                .refreshable {
                    await viewModel.refreshData()
                }
        }
    }
    
    private var content: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let message):
                ErrorView(error: message) {
                    Task {
                        await viewModel.loadInitialData()
                    }
                }
            case .loaded, .idle, .results:
                timelineContent
            case .searching:
                Text("Searching...")
                    .font(.headline)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .multilineTextAlignment(.center)
            case .noResults:
                Text("No Results Found")
                    .font(.headline)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .multilineTextAlignment(.center)
            @unknown default:
                fatalError()
            }
        }
        .task {
            await viewModel.loadInitialData()
        }
    }
    
    private var timelineContent: some View {
        VStack(alignment: .leading) {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.dateRange, id: \.self) { date in
                        let tasksForDate = viewModel.tasksForDate(date)
                        if !tasksForDate.isEmpty {
                            dateSection(date: date, tasks: tasksForDate)
                        }
                    }
                }
                .padding()
            }
            
            bottomControls
        }
    }
    
    private func dateSection(date: Date, tasks: [TimelineTask]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 16) {
                Text(DateFormatter.sharedDateFormatter.string(from: date))
                    .font(.headline)
                    .frame(width: 120, alignment: .leading)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                if tasks.isEmpty {
                    Text("No tasks")
                        .foregroundColor(.gray)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(tasks, id: \.id) { task in
                            TaskView(task: task)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            
            Divider()
        }
    }
    
    private var bottomControls: some View {
        HStack {
            filterControls
            Spacer()
            dateToggle
        }
        .padding()
    }
    
    private var filterControls: some View {
        Menu {
            Picker(selection: $viewModel.selectedFilter, label: EmptyView()) {
                Text("All").tag(TimelineFilter.all)
                Text("Inbox").tag(TimelineFilter.inbox)
                ForEach(viewModel.taskLists, id: \.listID) { list in
                    Text(list.name ?? "Unnamed List")
                        .tag(TimelineFilter.specificList(list))
                }
            }
        } label: {
            Label("List Filter", systemImage: "line.3.horizontal.decrease.circle")
                .font(.headline)
                .padding(8)
        }
    }
    
    private var dateToggle: some View {
        Menu {
            Picker(selection: $viewModel.isStartDate, label: EmptyView()) {
                Text("Start Date").tag(true)
                Text("End Date").tag(false)
            }
        } label: {
            Label("Date Filter", systemImage: "calendar")
                .font(.headline)
                .padding(8)
        }
    }
}
