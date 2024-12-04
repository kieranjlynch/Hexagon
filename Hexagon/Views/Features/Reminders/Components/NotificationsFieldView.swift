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
    @State private var selectedOption: String = "none"
    
    private let notificationOptions = [
        (id: "none", title: "None"),
        (id: "time:15 minutes before", title: "15 minutes before"),
        (id: "time:30 minutes before", title: "30 minutes before"),
        (id: "time:1 hour before", title: "1 hour before"),
        (id: "time:6 hours before", title: "6 hours before"),
        (id: "time:12 hours before", title: "12 hours before"),
        (id: "time:24 hours before", title: "24 hours before")
    ]
    
    var body: some View {
        Menu {
            ForEach(notificationOptions, id: \.id) { option in
                Button {
                    selectedOption = option.id
                    if option.id == "none" {
                        selectedNotifications.removeAll()
                    } else {
                        selectedNotifications = [option.id]
                    }
                } label: {
                    if selectedOption == option.id {
                        Label(option.title, systemImage: "checkmark")
                    } else {
                        Text(option.title)
                    }
                }
            }
        } label: {
            Text(notificationOptions.first { $0.id == selectedOption }?.title ?? "None")
                .foregroundColor(.blue)
        }
        .onAppear {
            selectedOption = selectedNotifications.first ?? "none"
        }
    }
}
