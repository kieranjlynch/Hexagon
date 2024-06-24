import Foundation
import UIKit
import MapKit

public struct ReminderEditConfig {
    var title: String = ""
    var notes: String?
    public var isCompleted: Bool = false
    var hasDate: Bool = false
    var hasTime: Bool = false
    var reminderDate: Date?
    var reminderTime: Date?
    var startDate: Date?
    var endDate: Date?
    var priority: Int = 0
    var tag: String?
    var url: String?
    var photos: [UIImage] = []
    
    public init() { }
    
    init(reminder: Reminder) {
        title = reminder.title ?? ""
        notes = reminder.notes
        isCompleted = reminder.isCompleted
        endDate = reminder.endDate
        reminderTime = reminder.reminderTime
        hasDate = reminder.endDate != nil
        hasTime = reminder.reminderTime != nil
        priority = Int(reminder.priority)
    }
}
