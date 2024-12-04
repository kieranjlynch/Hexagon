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
        VStack(alignment: .leading, spacing: 8) {
            Label("Link", systemImage: "link")
                .foregroundColor(.primary)
            
            TextField("https://", text: $url)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.URL)
                .autocapitalization(.none)
                .autocorrectionDisabled()
            
            if !url.isEmpty {
                if let urlLink = URL(string: url),
                   let scheme = urlLink.scheme?.lowercased(),
                   (scheme == "http" || scheme == "https"),
                   urlLink.host != nil {
                    Text(url)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                } else {
                    Text("Invalid URL")
                        .foregroundColor(.red)
                }
            }
        }
    }
}
