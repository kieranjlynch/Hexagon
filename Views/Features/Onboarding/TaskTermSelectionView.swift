//
//  TaskTypeSelectionView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 12/09/2024.
//

import SwiftUI

struct TaskTermSelectionView: View {
    @AppStorage("preferredTaskType") private var preferredTaskType: String = "Tasks"
    @State private var selectedType: String?
    @Environment(\.colorScheme) var colorScheme
    
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Which term do you prefer?")
                .font(.title)
                .multilineTextAlignment(.center)
                .adaptiveForegroundAndBackground()
            
            ForEach(["Tasks", "Reminders", "To-Dos"], id: \.self) { type in
                CustomButton(
                    title: type,
                    action: {
                        selectedType = type
                    },
                    style: selectedType == type ? .primary : .secondary
                )
                .frame(maxWidth: .infinity)
            }
            
            Spacer()
            
            CustomButton(
                title: "Save",
                action: {
                    if let selected = selectedType {
                        preferredTaskType = selected
                        onContinue()
                    }
                },
                style: selectedType != nil ? .primary : .secondary
            )
            .frame(maxWidth: .infinity)
            .disabled(selectedType == nil)
        }
        .padding()
        .adaptiveForegroundAndBackground()
    }
}
