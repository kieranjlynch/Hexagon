//
//  ToggleTaskCompletionIntent.swift
//  HexagonTaskManager
//
//  Created by Kieran Lynch on 24/06/2024.
//

import AppIntents
import SwiftUI

public struct ToggleTaskCompletionIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Task Completion"
    public static var description = IntentDescription("Toggles the completion status of a task.")

    @Parameter(title: "Reminder ID")
    public var reminderId: String

    public init() {}

    public init(reminderId: String) {
        self.reminderId = reminderId
    }

    public func perform() async throws -> some IntentResult {
        let reminderService = ReminderService()
        guard let uuid = UUID(uuidString: reminderId),
              let reminder = try reminderService.getReminderById(id: uuid) else {
            throw Error.reminderNotFound
        }

        reminder.isCompleted.toggle()
        try reminderService.save()

        return .result()
    }

    public enum Error: Swift.Error {
        case reminderNotFound
    }
}
