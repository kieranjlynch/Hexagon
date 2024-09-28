//
//  SettingsView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @SceneStorage("SettingsView.selectedSection") private var selectedSection: String?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    settingsNavigationLink("Appearance")
                    settingsNavigationLink("Layout")
                    settingsNavigationLink("Dates")
                    settingsNavigationLink("Times")
                    settingsNavigationLink("Permissions")
                    settingsNavigationLink("Notifications")
                }
            }
            .listSettings()
            .navigationBarSetup(title: "Settings")
            .navigationDestination(for: String.self) { value in
                settingsNavigationDestination(value: value)
            }
        }
    }
    
    @ViewBuilder
    private func settingsNavigationLink(_ title: String) -> some View {
        NavigationLink(value: title) {
            Text(title)
        }
        .adaptiveColors()
    }
    
    @ViewBuilder
    private func settingsNavigationDestination(value: String) -> some View {
        switch value {
        case "Appearance":
            AppearanceSettingsView()
        case "Layout":
            LayoutSettingsView()
        case "Dates":
            DateSettingsView()
        case "Times":
            TimeSettingsView()
        case "Permissions":
            PermissionsView(onContinue: {}, isInSettings: true)
        case "Notifications":
            NotificationSettingsView()
        default:
            EmptyView()
        }
    }
}
