//
//  PhotosFieldView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI

struct PhotosFieldView: View {
    @Binding var selectedPhotos: [UIImage]
    var colorScheme: ColorScheme
    @Binding var isShowingImagePicker: Bool
    @Binding var expandedPhotoIndex: Int?
    
    var body: some View {
        VStack(alignment: .leading) {
            Button(action: { isShowingImagePicker = true }) {
                Label {
                    Text("Photos")
                } icon: {
                    Image(systemName: "photo.badge.plus")
                }
                .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            if !selectedPhotos.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(selectedPhotos.indices, id: \.self) { index in
                            Image(uiImage: selectedPhotos[index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .onTapGesture {
                                    expandedPhotoIndex = index
                                }
                        }
                    }
                }
            }
        }
    }
}
