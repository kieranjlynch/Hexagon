//
//  PrioritySheetView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI

struct PrioritySheetView: View {
    @Environment(\.appTintColor) var appTintColor
    @Environment(\.colorScheme) var colorScheme
    @Binding var priority: Int

    var body: some View {
        List {
            priorityButton(text: "No Priority", value: 0)
            priorityButton(text: "Low Priority", value: 1)
            priorityButton(text: "Medium Priority", value: 2)
            priorityButton(text: "High Priority", value: 3)
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .adaptiveForegroundAndBackground()
    }

    private func priorityButton(text: String, value: Int) -> some View {
        Button(action: { priority = value }) {
            HStack {
                Text(text)
                    .adaptiveColors()
                Spacer()
                if priority == value {
                    Image(systemName: "checkmark")
                        .foregroundColor(appTintColor)
                }
            }
        }
    }
}
