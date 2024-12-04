//
//  TagsFieldView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI

struct TagsFieldView: View {
    @Binding var selectedTags: Set<ReminderTag>
    var colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Menu {
                Button {
                    selectedTags.removeAll()
                } label: {
                    if selectedTags.isEmpty {
                        Label("None", systemImage: "checkmark")
                    } else {
                        Text("None")
                    }
                }
                
                if !selectedTags.isEmpty {
                    ForEach(Array(selectedTags), id: \.self) { tag in
                        Button {
                            selectedTags.remove(tag)
                        } label: {
                            Label(tag.name ?? "", systemImage: "checkmark")
                        }
                    }
                }
            } label: {
                if selectedTags.isEmpty {
                    Text("None")
                        .foregroundColor(.blue)
                } else {
                    Text("\(selectedTags.count) selected")
                        .foregroundColor(.blue)
                }
            }
            
            if !selectedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(selectedTags), id: \.self) { tag in
                            Text(tag.name ?? "")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
    }
}
