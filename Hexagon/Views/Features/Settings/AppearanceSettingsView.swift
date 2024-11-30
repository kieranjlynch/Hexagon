//
//  AppearanceSettingsView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Form {
            Section(header: adaptiveSectionHeader(title: "App Tint Color")) {
                ColorPickerView(selectedColor: Binding(
                    get: { appSettings.appTintColor },
                    set: { newColor in
                        appSettings.appTintColorRed = Double(newColor.components.red)
                        appSettings.appTintColorGreen = Double(newColor.components.green)
                        appSettings.appTintColorBlue = Double(newColor.components.blue)
                    }
                ))
            }
        }
        .navigationBarSetup(title: "Appearance")
    }
}
