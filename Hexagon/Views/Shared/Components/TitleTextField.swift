//
//  TitleTextField.swift
//  Hexagon
//
//  Created by Kieran Lynch on 07/11/2024.
//

import SwiftUI

struct TitleTextField: View {
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme
    var placeholder: String?
    
    var body: some View {
        TextField("", text: $text)
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .placeholder(when: text.isEmpty) {
                if let placeholder = placeholder {
                    Text(placeholder)
                        .foregroundColor(.gray)
                }
            }
    }
}

struct PlaceholderModifier: ViewModifier {
    let isShowing: Bool
    let placeholder: () -> Text
    
    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            if isShowing {
                placeholder()
            }
            content
        }
    }
}

extension View {
    func placeholder<T: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> T
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
