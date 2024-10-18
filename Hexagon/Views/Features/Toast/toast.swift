//
//  toast.swift
//  Hexagon
//
//  Created by Kieran Lynch on 17/10/2024.
//

import SwiftUI

struct Toast: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 14))
                Text("Undo")
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        .background(Color.black.opacity(0.7))
        .cornerRadius(20)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
