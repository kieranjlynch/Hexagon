//
//  TimelineView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 27/09/2024.
//

import SwiftUI
import HexagonData

struct HashableTimelineTask: Hashable {
    let task: TimelineTask
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(task.id)
    }
    
    static func == (lhs: HashableTimelineTask, rhs: HashableTimelineTask) -> Bool {
        return lhs.task.id == rhs.task.id
    }
}

struct UpcomingView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appSettings: AppSettings
    @ObservedObject private var viewModel: TimelineViewModel
    @State private var isStartDate = true
    
    init(fetchingService: ReminderFetchingService,
         listService: ListService) {
        _viewModel = ObservedObject(wrappedValue: TimelineViewModel(
            fetchingService: fetchingService,
            listService: listService
        ))
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                if viewModel.tasks.isEmpty {
                    ContentUnavailableView("No Tasks Available", systemImage: "calendar.badge.clock")
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(viewModel.dateRange, id: \.self) { date in
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack(alignment: .top, spacing: 10) {
                                        Text(DateFormatter.sharedDateFormatter.string(from: date))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .frame(width: 200, alignment: .leading)
                                        
                                        timelineRow(for: date)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    Spacer()
                    HStack {
                        filterControls
                        Spacer()
                        dateToggle
                    }
                    .padding()
                }
            }
            .navigationTitle("Timeline")
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
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .task {
                await viewModel.loadInitialData()
            }
        }
    }
    
    private var filterControls: some View {
        Menu {
            Picker(selection: $viewModel.selectedFilter, label: EmptyView()) {
                Text("All").tag(ListFilter.all)
                Text("Inbox").tag(ListFilter.inbox)
                ForEach(viewModel.taskLists, id: \.listID) { list in
                    Text(list.name ?? "Unnamed List").tag(ListFilter.specificList(list))
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
            Picker(selection: $isStartDate, label: EmptyView()) {
                Text("Start Date").tag(true)
                Text("End Date").tag(false)
            }
        } label: {
            Label("Date Filter", systemImage: "line.3.horizontal.decrease.circle")
                .font(.headline)
                .padding(8)
        }
        .onChange(of: isStartDate) { _, newValue in
            viewModel.updateDateType(isStartDate: newValue)
        }
    }
    
    private func timelineRow(for date: Date) -> some View {
        let tasks = viewModel.tasksForDate(date)
        let hashableTasks = tasks.map { HashableTimelineTask(task: $0) }
        
        return Group {
            FlexibleView(data: hashableTasks, spacing: 5, alignment: .leading) { hashableTask in
                TaskView(task: hashableTask.task)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        if let format = DateFormat(rawValue: UserDefaults.standard.string(forKey: "dateFormat") ?? DateFormat.ddmmyyyy.rawValue) {
            let formatter = DateFormatter()
            formatter.dateFormat = format.rawValue
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = DateFormat.ddmmyyyy.rawValue
            return formatter.string(from: date)
        }
    }
}
