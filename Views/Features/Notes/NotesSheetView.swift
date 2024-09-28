//
//  NotesSheetView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI

struct NotesSheetView: View {
    @Binding var notes: String
    @FocusState private var isTextEditorFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            TextEditor(text: $notes)
                .standardBorderedTextEditor()
                .halfHeightOfContainer()
                .focused($isTextEditorFocused)
            Spacer()
        }
        .adaptiveForegroundAndBackground()
        .focusOnAppear($isTextEditorFocused)
    }
}
