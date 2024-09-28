//
//  NotificationsFieldView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI

struct NotificationsFieldView: View {
    @Binding var selectedNotifications: Set<String>
    var colorScheme: ColorScheme
    
    var body: some View {
        HStack {
            NavigationLink {
                NotificationSheetView(selectedNotifications: $selectedNotifications)
            } label: {
                Label {
                    Text("Notifications")
                } icon: {
                    Image(systemName: "app.badge.fill")
                }
                .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            Spacer()
            if !selectedNotifications.isEmpty {
                Image(systemName: "checkmark")
                    .foregroundColor(Color.accentColor)
            }
        }
    }
}
