//
//  TagsFieldView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI
import HexagonData

struct TagsFieldView: View {
    @Binding var selectedTags: Set<Tag>
    var colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                NavigationLink {
                    TagsSheetView(selectedTags: $selectedTags)
                } label: {
                    Label {
                        Text("Tags")
                    } icon: {
                        Image(systemName: "tag")
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                Spacer()
            }
            if !selectedTags.isEmpty {
                ScrollView(.horizontal) {
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
