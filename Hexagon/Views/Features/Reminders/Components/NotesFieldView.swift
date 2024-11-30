//
//  NotesFieldView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI

struct NotesFieldView: View {
    @Binding var notes: String
    var colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading) {
            NavigationLink {
                NotesSheetView(notes: $notes)
            } label: {
                Label {
                    Text("Notes")
                } icon: {
                    Image(systemName: "note.text")
                }
                .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .buttonStyle(PlainButtonStyle())
            if !notes.isEmpty {
                Text(notes.components(separatedBy: .newlines).first ?? "")
                    .lineLimit(1)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
        }
    }
}
