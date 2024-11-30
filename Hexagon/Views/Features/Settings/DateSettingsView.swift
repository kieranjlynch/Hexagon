//
//  DateTimeSettingsView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI

struct DateSettingsView: View {
    @AppStorage("dateFormat") private var dateFormat = DateFormat.ddmmyy.rawValue
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Picker("Select Date Format", selection: $dateFormat) {
                ForEach(DateFormat.allCases, id: \.self) { format in
                    Text(format.description).tag(format.rawValue)
                }
            }
            .pickerStyle(WheelPickerStyle())
        }
        .navigationTitle("Date Format")
        .onChange(of: dateFormat) { _, newValue in
            DateFormatter.updateSharedDateFormatter()
            NotificationCenter.default.post(name: .dateFormatChanged, object: nil)
        }
    }
}
