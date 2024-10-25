//
//  TimelineViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 03/10/2024.
//

import Foundation
import SwiftUI
import CoreData
import HexagonData
import Combine

class TimelineViewModel: ObservableObject {
    @Published var tasks: [TimelineTask] = []
    @Published var taskLists: [TaskList] = []
    @Published var selectedFilter: ListFilter = .all {
        didSet {
            applyFilter(selectedFilter)
        }
    }
    @Published var error: IdentifiableError?
    @Published var dateRange: [Date] = []
    
    private var isStartDate = true
    private var cancellables = Set<AnyCancellable>()  
    
    private let reminderService: ReminderService
    private let listService: ListService
    
    init(reminderService: ReminderService, listService: ListService) {
        self.reminderService = reminderService
        self.listService = listService

        $tasks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateDateRange()
            }
            .store(in: &cancellables)

        $selectedFilter
            .receive(on: DispatchQueue.main)
            .sink { [weak self] filter in
                self?.applyFilter(filter)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Async/Await functions

    func loadInitialData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadTasks() }
            group.addTask { await self.loadTaskLists() }
        }
    }
    
    @MainActor
    func loadTasks() async {
        do {
            let reminders = try await reminderService.fetchReminders()
            self.tasks = reminders.map { reminder in
                TimelineTask(
                    id: reminder.reminderID ?? UUID(),
                    title: reminder.title ?? "Untitled",
                    startDate: reminder.startDate ?? Date(),
                    endDate: reminder.endDate,
                    list: reminder.list,
                    isCompleted: reminder.isCompleted
                )
            }
        } catch {
            self.error = IdentifiableError(message: error.localizedDescription)
        }
    }
    
    @MainActor
    func loadTaskLists() async {
        do {
            self.taskLists = try await listService.updateTaskLists()
        } catch {
            self.error = IdentifiableError(message: error.localizedDescription)
        }
    }

    @MainActor
    func toggleCompletion(_ task: TimelineTask) async {
        do {
            let context = reminderService.persistentContainer.viewContext
            let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "reminderID == %@", task.id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            if let reminder = try await context.perform({ try fetchRequest.execute().first }) {
                try await reminderService.updateReminderCompletionStatus(reminder: reminder, isCompleted: !reminder.isCompleted)
                await loadTasks()
            }
        } catch {
            self.error = IdentifiableError(message: error.localizedDescription)
        }
    }
    
    // MARK: - Combine-driven logic for reactive UI updates

    var fullDateRange: [Date] {
        guard let firstDate = dateRange.first, let lastDate = dateRange.last else {
            return []
        }
        return generateFullDateRange(from: firstDate, to: lastDate)
    }
    
    private func generateFullDateRange(from startDate: Date, to endDate: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = startDate
        let calendar = Calendar.current
        
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dates
    }
    
    func tasksForDate(_ date: Date) -> [TimelineTask] {
        let calendar = Calendar.current
        return filteredTasks().filter { task in
            let taskDate = isStartDate ? task.startDate : (task.endDate ?? task.startDate)
            return calendar.isDate(taskDate, inSameDayAs: date)
        }
    }
    
    func updateDateType(isStartDate: Bool) {
        self.isStartDate = isStartDate
        updateDateRange()
    }
    
    func updateDateRange() {
        let dates = tasks.map { task in
            isStartDate ? task.startDate : (task.endDate ?? task.startDate)
        }
        let uniqueDates = Set(dates.map { Calendar.current.startOfDay(for: $0) })
        self.dateRange = Array(uniqueDates).sorted()
    }
    
    func applyFilter(_ filter: ListFilter) {
        updateDateRange()
    }
    
    func filteredTasks() -> [TimelineTask] {
        switch selectedFilter {
        case .all:
            return tasks
        case .inbox:
            return tasks.filter { $0.list == nil }
        case .specificList(let list):
            return tasks.filter { $0.list?.listID == list.listID }
        }
    }
}
