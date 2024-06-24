import Foundation
import CoreData
import SwiftUI

public struct ReminderStatsValues {
    public var todayCount: Int = 0
    public var scheduledCount: Int = 0
    public var allCount: Int = 0
    public var completedCount: Int = 0
    
    public init(todayCount: Int = 0, scheduledCount: Int = 0, allCount: Int = 0, completedCount: Int = 0) {
        self.todayCount = todayCount
        self.scheduledCount = scheduledCount
        self.allCount = allCount
        self.completedCount = completedCount
    }
}

public struct ReminderStats {
    public init() {}
    
    public func build(myListResults: FetchedResults<TaskList>) -> ReminderStatsValues {
        let remindersArray = myListResults.map { $0.reminders?.allObjects.compactMap { ($0 as! Reminder) } ?? [] }.reduce([], +)
        
        let todaysCount = calculateTodaysCount(reminders: remindersArray)
        let scheduledCount = calculateScheduledCount(reminders: remindersArray)
        let completedCount = calculateCompletedCount(reminders: remindersArray)
        let allCount = calculateAllCount(reminders: remindersArray)
        
        return ReminderStatsValues(todayCount: todaysCount, scheduledCount: scheduledCount, allCount: allCount, completedCount: completedCount)
    }
    
    private func calculateScheduledCount(reminders: [Reminder]) -> Int {
        return reminders.reduce(0) { result, reminder in
            return ((reminder.endDate != nil || reminder.reminderTime != nil) && !reminder.isCompleted) ? result + 1 : result
        }
    }
    
    private func calculateTodaysCount(reminders: [Reminder]) -> Int {
        return reminders.reduce(0) { result, reminder in
            let isToday = reminder.endDate?.isToday ?? false
            return isToday ? result + 1 : result
        }
    }
    
    private func calculateCompletedCount(reminders: [Reminder]) -> Int {
        return reminders.reduce(0) { result, reminder in
            return reminder.isCompleted ? result + 1 : result
        }
    }
    
    private func calculateAllCount(reminders: [Reminder]) -> Int {
        return reminders.reduce(0) { result, reminder in
            return !reminder.isCompleted ? result + 1 : result
        }
    }
}


extension Date {
    var isToday: Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(self)
    }
}
