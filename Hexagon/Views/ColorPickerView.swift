//
//  ColorPickerView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI

struct ColorPickerView: View {
    @Binding var selectedColor: Color
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .mint, .indigo, .teal]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<2) { row in
                HStack(spacing: 14) {
                    ForEach(0..<5) { column in
                        let colorIndex = row * 5 + column
                        if colorIndex < colors.count {
                            let color = colors[colorIndex]
                            colorCircle(isSelected: selectedColor == color, color: color)
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 5)
        .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
    }
    
    // MARK: - Color Circle
    private func colorCircle(isSelected: Bool, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
            Circle()
                .strokeBorder(isSelected ? Color.gray : Color.clear, lineWidth: 2)
                .frame(width: 43, height: 43)
        }
    }
}
