import SwiftUI

struct NotesSheetView: View {
    @Binding var notes: String
    
    var body: some View {
        Form {
            TextField("Notes", text: $notes, axis: .vertical)
                .foregroundColor(.offWhite)
                .lineLimit(1...5)
        }
        .listRowBackground(Color.customBackgroundColor)
        .environment(\.colorScheme, .dark)
    }
}
