//
//  PhotosSheetView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI

struct PhotosSheetView: View {
    @Binding var selectedPhotos: [UIImage]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            addPhotoButton
            photoScrollView
        }
        .adaptiveForegroundAndBackground()
    }
    
    private var addPhotoButton: some View {
        Button(action: {

        }) {
            Image(systemName: "plus")
                .adaptiveColors()
        }
    }
    
    private var photoScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(selectedPhotos, id: \.self) { photo in
                    photoThumbnail(uiImage: photo)
                }
            }
        }
    }
}
