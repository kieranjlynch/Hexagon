//
//  ButtonRowView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI

struct ButtonRowView: View {
    let isFormValid: Bool
    let saveAction: () async -> Void
    let dismissAction: () -> Void
    var colorScheme: ColorScheme
    
    var body: some View {
        HStack {
            CustomButton(title: "Cancel", action: dismissAction, style: .secondary)
            
            CustomButton(title: "Save", action: {
                Task {
                    await saveAction()
                }
            }, style: .primary)
            .disabled(!isFormValid)
        }
        .padding()
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}
