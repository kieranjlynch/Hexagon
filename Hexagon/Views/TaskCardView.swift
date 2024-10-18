//
//  TaskCardView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import EventKit
import HexagonData

struct TaskCardView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var reminderService: ReminderService
    let reminder: Reminder
    let onTap: () -> Void
    let onToggleCompletion: () -> Void
    let selectedDate: Date
    let selectedDuration: Double

    @State private var isTogglingCompletion = false

    var body: some View {
        HStack {
            toggleCompletionButton
            taskDetails
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .cardStyle()
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(reminder.title ?? "Untitled Task")
        .accessibilityHint("Double-tap for more options")
    }

    private var toggleCompletionButton: some View {
        completionToggleButton(isCompleted: reminder.isCompleted, action: toggleCompletion)
    }

    private var taskDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            taskTitle
            dueDate
            taskIcons
        }
    }

    private var taskTitle: some View {
        Text("Task: \(reminder.title ?? "Untitled Task")")
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .font(.headline)
            .strikethrough(reminder.isCompleted)
            .accessibilityLabel("Task title")
            .accessibilityValue(reminder.title ?? "Untitled Task")
            .accessibilityHint("Double-tap to view or edit this task")
    }

    private var dueDate: some View {
        Group {
            if let dueDate = reminder.endDate {
                Text("Due: \(formatDate(dueDate))")
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .font(.caption)
                    .accessibilityLabel("Due date")
                    .accessibilityValue(formatDate(dueDate))
            }
        }
    }

    private var taskIcons: some View {
        HStack(spacing: 8) {
            if !reminder.tagsArray.isEmpty {
                taskIcon(systemName: "tag", label: "Has tags", hint: "Double-tap to view tags")
            }
            if !reminder.photosArray.isEmpty {
                taskIcon(systemName: "photo", label: "Has photos", hint: "Double-tap to view attached photos")
            }
            if !reminder.notificationsArray.isEmpty {
                taskIcon(systemName: "bell", label: "Has notifications", hint: "Double-tap to view notifications")
            }
            if reminder.voiceNote != nil {
                taskIcon(systemName: "waveform", label: "Has voice memo", hint: "Double-tap to listen to voice memo")
            }
        }
    }

    private func taskIcon(systemName: String, label: String, hint: String) -> some View {
        taskIconView(systemName: systemName, label: label, hint: hint, tintColor: appSettings.appTintColor)
    }

    private func toggleCompletion() {
        guard !isTogglingCompletion else { return }
        isTogglingCompletion = true
        Task {
            onToggleCompletion()
            isTogglingCompletion = false
        }
    }

    private func formatDate(_ date: Date) -> String {
        return DateFormatter.sharedDateFormatter.string(from: date)
    }
}
