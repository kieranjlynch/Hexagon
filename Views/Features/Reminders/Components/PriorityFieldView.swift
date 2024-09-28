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
    
    var body: some View {
        HStack {
            NavigationLink {
                PrioritySheetView(priority: $priority)
            } label: {
                Label {
                    Text("Priority")
                } icon: {
                    Image(systemName: "flag")
                }
                .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            Spacer()
            if priority != 0 {
                Text(priorityText(priority: priority))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.UI.cornerRadius)
            }
        }
    }
    
    private func priorityText(priority: Int) -> String {
        switch priority {
        case 1:
            return "Low"
        case 2:
            return "Medium"
        case 3:
            return "High"
        default:
            return "None"
        }
    }
}
