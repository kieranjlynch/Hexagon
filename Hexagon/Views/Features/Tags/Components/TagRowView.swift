//
//  TagRowView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI
import HexagonData

struct TagRowView: View {
    let tag: ReminderTag
    let isSelected: Bool
    let appTintColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(tag.name ?? "")
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(appTintColor)
                }
            }
        }
    }
}
