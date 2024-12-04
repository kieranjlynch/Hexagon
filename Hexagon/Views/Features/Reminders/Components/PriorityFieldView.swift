//
//  PriorityFieldView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI

struct PriorityFieldView: View {
    @Binding var priority: Int
    var colorScheme: ColorScheme
    
    private let priorities = [
        (0, "None"),
        (1, "Low"),
        (2, "Medium"),
        (3, "High")
    ]
    
    var body: some View {
        Menu {
            ForEach(priorities, id: \.0) { value, label in
                Button {
                    priority = value
                } label: {
                    if priority == value {
                        Label(label, systemImage: "checkmark")
                    } else {
                        Text(label)
                    }
                }
            }
        } label: {
            Text(priorities.first { $0.0 == priority }?.1 ?? "None")
                .foregroundColor(.blue)
        }
    }
}

extension Color {
    static func priorityColor(for priority: Int) -> Color {
        switch priority {
        case 1: return .blue
        case 2: return .orange
        case 3: return .red
        default: return .gray
        }
    }
}
