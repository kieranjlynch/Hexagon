//
//  NotificationSheetView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI


struct NotificationSheetView: View {
    @Environment(\.appTintColor) var appTintColor
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var fetchingService: ReminderFetchingServiceUI
    @EnvironmentObject private var modificationService: ReminderModificationService
    @Binding var selectedNotifications: Set<String>
    @State private var isShowingMap = false
    
    let reminderTimes = [
        "15 minutes before",
        "30 minutes before",
        "1 hour before",
        "6 hours before",
        "12 hours before",
        "24 hours before"
    ]
    
    var body: some View {
        Form {
            Section(header: adaptiveSectionHeader(title: "Reminder Time")) {
                ForEach(reminderTimes, id: \.self) { time in
                    reminderTimeRow(for: time)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .adaptiveBackground()
    }
    
    private func reminderTimeRow(for time: String) -> some View {
        Button(action: {
            toggleReminderTime(time)
        }) {
            HStack {
                Text(time)
                    .adaptiveColors()
                Spacer()
                if selectedNotifications.contains(time) {
                    Image(systemName: "checkmark")
                        .foregroundColor(appTintColor)
                }
            }
        }
    }
    
    private func toggleReminderTime(_ time: String) {
        if selectedNotifications.contains(time) {
            selectedNotifications.remove(time)
        } else {
            selectedNotifications.insert(time)
        }
    }
}
