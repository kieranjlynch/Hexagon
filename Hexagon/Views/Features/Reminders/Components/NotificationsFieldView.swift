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
        NavigationLink {
            NotificationNavigationView(selectedNotifications: $selectedNotifications)
        } label: {
            HStack {
                Label {
                    Text("Notifications")
                } icon: {
                    Image(systemName: "app.badge.fill")
                }
                .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Spacer()
                
                if !selectedNotifications.isEmpty {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color.accentColor)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct NotificationNavigationView: View {
    @Binding var selectedNotifications: Set<String>
    @StateObject private var locationViewModel = LocationViewModel(
        locationService: LocationService.shared,
        searchService: MapSearchService.shared,
        permissionsHandler: LocationPermissionManager.shared
    )
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        List {
            Section("Reminder Time") {
                ForEach(["15 minutes before", "30 minutes before", "1 hour before", "6 hours before", "12 hours before", "24 hours before"], id: \.self) { time in
                    Button {
                        let timeId = "time:\(time)"
                        if selectedNotifications.contains(timeId) {
                            selectedNotifications.remove(timeId)
                        } else {
                            selectedNotifications.insert(timeId)
                        }
                    } label: {
                        HStack {
                            Text(time)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Spacer()
                            if selectedNotifications.contains("time:\(time)") {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            
            if !locationViewModel.locations.isEmpty {
                Section("Remind me at") {
                    ForEach(locationViewModel.locations) { location in
                        Button {
                            let locationId = "location:\(location.id.uuidString)"
                            if selectedNotifications.contains(locationId) {
                                selectedNotifications.remove(locationId)
                            } else {
                                selectedNotifications.insert(locationId)
                            }
                        } label: {
                            HStack {
                                Text(location.name)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                Spacer()
                                if selectedNotifications.contains("location:\(location.id.uuidString)") {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}
