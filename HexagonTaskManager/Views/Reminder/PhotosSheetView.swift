import SwiftUI

struct PhotosSheetView: View {
    @Binding var selectedPhotos: [UIImage]
    
    var body: some View {
        VStack {
            Button(action: {
                // Show image picker
            }) {
                Image(systemName: "plus")
                    .foregroundColor(.offWhite)
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(selectedPhotos, id: \.self) { photo in
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 100)
                    }
                }
            }
        }
        .listRowBackground(Color.customBackgroundColor)
        .environment(\.colorScheme, .dark)
    }
}
