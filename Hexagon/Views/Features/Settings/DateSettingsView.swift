//
//  DateTimeSettingsView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI

struct DateSettingsView: View {
    @AppStorage("dateFormat") private var dateFormat = DateFormat.ddmmyy.rawValue
    
    var body: some View {
        Form {
            Section(header: Text("Date Format")) {
                Picker("Select Date Format", selection: $dateFormat) {
                    ForEach(DateFormat.allCases, id: \.self) { format in
                        Text(format.description).tag(format.rawValue)
                    }
                }
                .pickerStyle(WheelPickerStyle()) 
            }
        }
        .navigationTitle("Date Settings")
        .onChange(of: dateFormat) { _, newValue in
            DateFormatter.updateSharedDateFormatter()
        }
    }
}
