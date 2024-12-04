//
//  TitleFieldView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI

struct TitleFieldView: View {
    @Binding var title: String
    let taskType: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("")
                .font(.subheadline)
                .foregroundColor(.gray)
            TitleTextField(
                text: $title,
                placeholder: "\(taskType.dropLast()) title"
            )
        }
    }
}
