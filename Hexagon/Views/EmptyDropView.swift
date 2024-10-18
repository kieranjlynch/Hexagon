//
//  EmptyDropView.swift
//  Hexagon
//
//  Created by Darren Allen on 15/10/2024.
//

import SwiftUI

struct EmptyDropView: View {
    var body: some View {
        Image(systemName: "arrow.down.app")
            .padding(.vertical, 10)
            .foregroundColor(Color(UIColor.systemBackground))
            .frame(maxWidth: .infinity, maxHeight: 30)
            .background(Color(UIColor.systemBackground))
            .opacity(0.3)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 8
                )
            )
            .padding(.horizontal, 10)
    }
}

#Preview {
    EmptyDropView()
}
