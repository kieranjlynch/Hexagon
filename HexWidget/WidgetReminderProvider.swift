//
//  WidgetReminderProvider.swift
//  HexWidget
//
//  Created by Kieran Lynch on 04/11/2024.
//

import Foundation
import CoreData


@MainActor
public class WidgetReminderProvider {
    private let reminderFetchingService: ReminderFetchingService
    
    public init(reminderFetchingService: ReminderFetchingService) {
        self.reminderFetchingService = reminderFetchingService
    }
    
    public func getRemindersForList(_ taskList: TaskList) async throws -> [Reminder] {
        let predicate = PredicateRepresentation(
            format: "list == %@ AND isCompleted == %@",
            arguments: [taskList, NSNumber(value: false)]
        )
        
        let sortDescriptors = [
            SortDescriptorRepresentation(key: "startDate", ascending: true),
            SortDescriptorRepresentation(key: "order", ascending: true)
        ]
        
        return try await reminderFetchingService.executeFetchRequest(
            entity: Reminder.self,
            predicateRepresentation: predicate,
            sortDescriptorRepresentations: sortDescriptors
        )
    }
}
