//
//  FilterType.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI

public enum FilterType: String, Codable, CaseIterable {
    case today, scheduled, all, completed, withNotes, withURL, withPriority, withTag, overdue, withLocation, withPhoto
    case single, group
    
    var icon: String {
        switch self {
        case .today: return "calendar.circle.fill"
        case .scheduled: return "calendar.circle.fill"
        case .all: return "tray.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .withNotes: return "doc.circle.fill"
        case .withURL: return "link.circle.fill"
        case .withPriority: return "exclamationmark.circle.fill"
        case .withTag: return "tag.circle.fill"
        case .overdue: return "clock.circle.fill"
        case .withLocation: return "location.circle.fill"
        case .withPhoto: return "photo.circle.fill"
        case .single, .group: return "questionmark.circle.fill"
        }
    }
    
    var title: String {
        switch self {
        case .today: return "Today"
        case .scheduled: return "Scheduled"
        case .all: return "All"
        case .completed: return "Completed"
        case .withNotes: return "Notes"
        case .withURL: return "Link"
        case .withPriority: return "Priority"
        case .withTag: return "Tag"
        case .overdue: return "Overdue"
        case .withLocation: return "Location"
        case .withPhoto: return "Photo"
        case .single: return "Single"
        case .group: return "Group"
        }
    }
    
    var reminderStatType: ReminderStatType {
        switch self {
        case .today: return .today
        case .scheduled: return .scheduled
        case .all: return .all
        case .completed: return .completed
        case .withNotes: return .withNotes
        case .withURL: return .withURL
        case .withPriority: return .withPriority
        case .withTag: return .withTag
        case .overdue: return .overdue
        case .withLocation: return .withLocation
        case .withPhoto: return .withPhoto
        case .single, .group: return .all
        }
    }
}

public enum ReminderStatType {
    case today, scheduled, all, completed, withNotes, withURL, withPriority, withTag, overdue, withLocation, withPhoto
}
