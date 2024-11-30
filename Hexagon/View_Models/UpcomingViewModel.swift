//
//  UpcomingViewModel.swift
//  Hexagon
//

import Foundation
import SwiftUI
import CoreData
import EventKit
import os
import Combine


public struct TimelineConfiguration {
    public let daysToShow: Int
    public let startDate: Date
    
    public static let `default` = TimelineConfiguration(daysToShow: 365, startDate: Date())
}

@MainActor
final class UpcomingViewModel: ObservableObject {
    @Published var state: ViewState<UpcomingViewState> = .idle
    @Published var selectedFilter: TimelineFilter = .all
    @Published var isStartDate: Bool = true
    @Published var taskLists: [TaskList] = []
    @Published var dateRange: [Date] = []
    @Published var error: IdentifiableError?
    
    var activeTasks = Set<Task<Void, Never>>()
    var cancellables = Set<AnyCancellable>()
    
    private let dataProvider: TimelineDataProvider
    private let calendarService: CalendarServiceProtocol
    private let configuration: TimelineConfiguration
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "UpcomingViewModel")
    private var isLoadingMore = false
    
    var tasks: [TimelineTask] {
        if case .loaded(let viewState) = state {
            return viewState.tasks
        }
        return []
    }
    
    init(
        dataProvider: TimelineDataProvider,
        calendarService: CalendarServiceProtocol,
        configuration: TimelineConfiguration = .default
    ) {
        self.dataProvider = dataProvider
        self.calendarService = calendarService
        self.configuration = configuration
        
        generateDateRange()
        
        Task {
            await loadTaskLists()
            await loadInitialData()
        }
    }
    
    func viewDidLoad() { }
    
    func viewWillAppear() { }
    
    func viewWillDisappear() {
        // Cancel any ongoing tasks
        activeTasks.forEach { $0.cancel() }
        activeTasks.removeAll()
    }
    
    func tasksForDate(_ date: Date) -> [TimelineTask] {
        let calendar = Calendar.current
        return tasks.filter { task in
            let taskDate = isStartDate ? task.startDate : (task.endDate ?? task.startDate)
            return calendar.isDate(taskDate, inSameDayAs: date)
        }
    }
    
    func updateDateFilter(isStartDate: Bool) {
        self.isStartDate = isStartDate
        generateDateRange()
        
        if case .loaded(var viewState) = state {
            viewState.isStartDate = isStartDate
            state = .loaded(viewState)
        }
    }
    
    private func fetchCalendarEvents() async -> [EKEvent] {
        do {
            let hasAccess = try await calendarService.requestCalendarAccess()
            guard hasAccess,
                  let startDate = dateRange.first,
                  let endDate = dateRange.last else {
                return []
            }
            
            return await calendarService.fetchEvents(from: startDate, to: endDate)
        } catch {
            logger.error("Failed to fetch calendar events: \(error.localizedDescription)")
            return []
        }
    }
    
    func loadInitialData() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        state = .loading
        
        do {
            async let remindersTask = fetchReminders()
            async let eventsTask = fetchCalendarEvents()
            
            let (reminders, events) = try await (remindersTask, eventsTask)
            
            var viewState = UpcomingViewState()
            updateTasks(reminders: reminders, calendarEvents: events, state: &viewState)
            state = .loaded(viewState)
        } catch {
            state = .error(error.localizedDescription)
            self.error = IdentifiableError(error: error)
            logger.error("Failed to load initial data: \(error.localizedDescription)")
        }
        
        isLoadingMore = false
    }
    
    func refreshData() async {
        await loadTaskLists()
        await loadInitialData()
    }
    
    private func generateDateRange() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { return }
        
        dateRange = (0...configuration.daysToShow).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: tomorrow)
        }
    }
    
    private func fetchReminders() async throws -> [Reminder] {
        let calendar = Calendar.current
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        return try await dataProvider.fetchTasks(from: startOfTomorrow, filter: .all)
    }
    
    private func loadTaskLists() async {
        do {
            taskLists = try await dataProvider.fetchTaskLists()
        } catch {
            logger.error("Error loading task lists: \(error.localizedDescription)")
            self.error = IdentifiableError(error: error)
        }
    }
    
    private func updateTasks(reminders: [Reminder], calendarEvents: [EKEvent], state: inout UpcomingViewState) {
        let reminderTasks = reminders.compactMap { reminder -> TimelineTask? in
            guard let startDate = reminder.startDate else { return nil }
            return TimelineTask(
                id: reminder.reminderID ?? UUID(),
                title: reminder.title ?? "",
                startDate: startDate,
                endDate: reminder.endDate,
                list: reminder.list,
                isCompleted: reminder.isCompleted,
                isCalendarEvent: false
            )
        }
        
        let eventTasks = calendarEvents.map { TimelineTask(from: $0) }
        
        state.tasks = (reminderTasks + eventTasks)
            .sorted { lhs, rhs in
                let lhsDate = state.isStartDate ? lhs.startDate : (lhs.endDate ?? lhs.startDate)
                let rhsDate = state.isStartDate ? rhs.startDate : (rhs.endDate ?? rhs.startDate)
                return lhsDate < rhsDate
            }
    }
}

struct UpcomingViewState: Equatable {
    var tasks: [TimelineTask] = []
    var taskLists: [TaskList] = []
    var dateRange: [Date] = []
    var isStartDate: Bool = true
    var selectedFilter: TimelineFilter = .all
}

enum TimelineError: LocalizedError {
    case invalidDate
    case fetchFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidDate:
            return "Invalid date for timeline generation"
        case .fetchFailed(let error):
            return "Failed to fetch timeline data: \(error.localizedDescription)"
        }
    }
}
