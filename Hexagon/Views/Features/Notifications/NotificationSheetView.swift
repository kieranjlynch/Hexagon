//
//  NotificationSheetView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import HexagonData

struct NotificationSheetView: View {
    @Environment(\.appTintColor) var appTintColor
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var reminderService: ReminderService
    @EnvironmentObject private var locationService: LocationService
    @Binding var selectedNotifications: Set<String>
    @State private var selectedLocation: Location?
    @State private var locations: [Location] = []
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
            
            Section(header: adaptiveSectionHeader(title: "Locations")) {
                styledButton(title: "Add New Location", style: CustomButtonStyle.secondary, appTintColor: appTintColor) {
                    isShowingMap = true
                }
                
                ForEach(locations, id: \.id) { location in
                    locationRow(for: location)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .adaptiveBackground()
        .sheet(isPresented: $isShowingMap) {
            LocationView(locationService: locationService, isPresented: $isShowingMap) { name, latitude, longitude in
                Task {
                    await saveLocation(name: name, latitude: latitude, longitude: longitude)
                }
                return .success(())
            }
        }
        .task {
            await fetchLocations()
        }
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
    
    private func locationRow(for location: Location) -> some View {
        Button(action: {
            selectedLocation = location
        }) {
            HStack {
                Text(location.name ?? "")
                    .adaptiveColors()
                Spacer()
                if selectedLocation == location {
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
    
    private func fetchLocations() async {
        do {
            locations = try await locationService.fetchLocations()
        } catch {
            print("Error fetching locations: \(error)")
        }
    }
    
    private func saveLocation(name: String, latitude: Double, longitude: Double) async {
        do {
            let newLocation = try await locationService.saveLocation(name: name, latitude: latitude, longitude: longitude)
            selectedLocation = newLocation
            await fetchLocations()
        } catch {
            print("Error saving location: \(error)")
        }
    }
}
