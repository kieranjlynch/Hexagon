//
//  LinkFieldView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI

struct LinkFieldView: View {
    @Binding var url: String
    var colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                NavigationLink(destination: LinkSheetView(url: $url)) {
                    Label {
                        Text("Link")
                    } icon: {
                        Image(systemName: "link")
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()
            }
            .background(Color.clear)
            .cornerRadius(Constants.UI.cornerRadius)
            
            if !url.isEmpty {
                if let urlLink = URL(string: url),
                   let scheme = urlLink.scheme?.lowercased(),
                   (scheme == "http" || scheme == "https"),
                   urlLink.host != nil {
                    Text(url)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .padding(.horizontal)
                } else {
                    Text("Invalid URL")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
        }
    }
}
