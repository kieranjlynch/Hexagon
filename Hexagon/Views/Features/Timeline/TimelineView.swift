//
//  TimelineView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 27/09/2024.
//

import SwiftUI
import HexagonData

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
            .navigationTitle("Timeline")
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .task {
                await viewModel.loadTasks()
            }
        }
    }
    
    private var filterControls: some View {
        Picker("Filter", selection: $viewModel.selectedFilter) {
            Text("All").tag(ListFilter.all)
            Text("Inbox").tag(ListFilter.inbox)
            ForEach(viewModel.taskLists, id: \.listID) { list in
                Text(list.name ?? "Unnamed List").tag(ListFilter.specificList(list))
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
    
    private var dateToggle: some View {
        Picker("Date Type", selection: $isStartDate) {
            Text("Start Date").tag(true)
            Text("End Date").tag(false)
        }
        .pickerStyle(MenuPickerStyle())
        .onChange(of: isStartDate, initial: false) { oldValue, newValue in
            viewModel.updateDateType(isStartDate: newValue)
        }
    }
    
    private func timelineRow(for date: Date) -> some View {
        let tasks = viewModel.tasksForDate(date)
        
        return Group {
            HStack(alignment: .top, spacing: 10) {
                ForEach(tasks, id: \.id) { task in
                    TaskView(task: task)
                        .background(Color.clear)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
