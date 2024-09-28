//
//  ExpandedPhotoOverlayView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI

struct ExpandedPhotoOverlayView: View {
    @Binding var expandedPhotoIndex: Int?
    @Binding var selectedPhotos: [UIImage]

    var body: some View {
        Group {
            if let index = expandedPhotoIndex, index < selectedPhotos.count {
                ZStack {
                    Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { expandedPhotoIndex = nil }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }
                        Image(uiImage: selectedPhotos[index])
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                    }
                }
            }
        }
    }
}
