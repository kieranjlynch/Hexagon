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
                settingsNavigationLink("Appearance", icon: "drop.halffull", color: .blue)
                    .listRowSeparator(.hidden)
                settingsNavigationLink("Dates", icon: "calendar", color: .green)
                    .listRowSeparator(.hidden)
                settingsNavigationLink("Permissions", icon: "lock.open.fill", color: .orange)
                    .listRowSeparator(.hidden)
            }
            .padding(.top, 1)
            .listSettings()
            .navigationBarSetup(title: "Settings")
            .navigationDestination(for: String.self) { value in
                settingsNavigationDestination(value: value)
            }
        }
    }
    
    @ViewBuilder
    private func settingsNavigationLink(_ title: String, icon: String, color: Color) -> some View {
        NavigationLink(value: title) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
            }
        }
        .adaptiveColors()
    }
    
    @ViewBuilder
    private func settingsNavigationDestination(value: String) -> some View {
        switch value {
        case "Appearance":
            AppearanceSettingsView()
        case "Dates":
            DateSettingsView()
        case "Permissions":
            PermissionsView(onContinue: {}, isInSettings: true)
        default:
            EmptyView()
        }
    }
}
