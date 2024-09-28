//
//  ButtonRowView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI

struct ButtonRowView: View {
    var onCancel: () -> Void
    var onSave: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onCancel) {
                Text("Cancel")
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            Button(action: onSave) {
                Text("Save")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}
