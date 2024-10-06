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

struct TimelineView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: TimelineViewModel
    @State private var isStartDate = true
    @State private var selectedListFilter: ListFilter = .all
    
    init(reminderService: ReminderService, listService: ListService) {
        self._viewModel = StateObject(wrappedValue: TimelineViewModel(reminderService: reminderService, listService: listService))
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                if viewModel.tasks.isEmpty {
                    ContentUnavailableView("No Tasks Available", systemImage: "calendar.badge.clock")
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(viewModel.fullDateRange, id: \.self) { date in
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack(alignment: .top, spacing: 10) {
                                        Text(formatDate(date))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .frame(width: 90, alignment: .leading)
                                        
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
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .task {
                await viewModel.loadTasks()
                await viewModel.loadTaskLists()
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
        .onChange(of: isStartDate, initial: false) { oldValue, newValue in
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
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
