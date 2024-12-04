//
//  VoiceNoteButton.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI

struct VoiceNoteButton: View {
    @Binding var voiceNoteData: Data?
    var colorScheme: ColorScheme
    @State private var isShowingVoiceNote = false
    
    var body: some View {
        HStack {
            Label("Voice Note", systemImage: "mic")
                .foregroundColor(.primary)
                .frame(width: 100, alignment: .leading)
            
            Button {
                isShowingVoiceNote = true
            } label: {
                Text(voiceNoteData == nil ? "Record" : "Re-record")
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            if voiceNoteData != nil {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .sheet(isPresented: $isShowingVoiceNote) {
            VoiceNoteSheetView(voiceNoteData: $voiceNoteData)
        }
    }
}
