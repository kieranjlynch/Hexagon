//
//  VoiceNoteFieldView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI

struct VoiceNoteFieldView: View {
    @Binding var voiceNoteData: Data?
    var colorScheme: ColorScheme
    
    var body: some View {
        NavigationLink {
            VoiceNoteSheetView(voiceNoteData: $voiceNoteData)
        } label: {
            Label {
                Text("Voice Note")
            } icon: {
                Image(systemName: "mic")
            }
            .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .buttonStyle(PlainButtonStyle())
        Spacer()
        if voiceNoteData != nil {
            Image(systemName: "checkmark")
                .foregroundColor(Color.accentColor)
        }
    }
}
