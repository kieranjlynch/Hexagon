//
//  WidgetReminderCellView.swift
//  HexagonWidgetExtension
//
//  Created by Kieran Lynch on 24/06/2024.
//

import SwiftUI
import SharedDataFramework

struct WidgetReminderCellView: View {
    let reminder: Reminder
    let onToggleCompletion: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggleCompletion) {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(reminder.isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(reminder.title ?? "")
                .strikethrough(reminder.isCompleted)
                .foregroundColor(reminder.isCompleted ? .gray : .primary)
        }
    }
}
