//
//  ListDetailSheet.swift
//  Hexagon
//
//  Created by Kieran Lynch on 23/10/2024.
//

import SwiftUI
import HexagonData
import CoreData

public enum ListDetailSheet: Identifiable, Hashable {
    case addReminder(TaskList)
    case editReminder(Reminder, TaskList)
    case addSubHeading(TaskList, NSManagedObjectContext)
    case scheduleTask(String)
    
    public var id: String {
        switch self {
        case .addReminder: return "addReminder"
        case .editReminder: return "editReminder"
        case .addSubHeading: return "addSubHeading"
        case .scheduleTask: return "scheduleTask"
        }
    }
    
    public static func == (lhs: ListDetailSheet, rhs: ListDetailSheet) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@MainActor
public final class SheetCoordinator: ObservableObject {
    @Published public var currentSheet: ListDetailSheet?
    
    public init() {}
    
    public func present(_ sheet: ListDetailSheet) {
        currentSheet = sheet
    }
    
    public func dismiss() {
        currentSheet = nil
    }
}
