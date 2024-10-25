import SwiftUI

struct CustomSearchBar: View {
    @Binding var searchText: String
    @Binding var isEditing: Bool
    var onCommit: () -> Void // We'll trigger this on "Return" press

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Search", text: $searchText, onEditingChanged: { isEditingNow in
                    withAnimation {
                        isEditing = isEditingNow
                    }
                }, onCommit: { // This runs when Return is pressed
                    onCommit() // Trigger the search passed from the parent
                    withAnimation(.easeOut(duration: 0.1)) {
                        isEditing = false
                    }
                })
                .foregroundColor(.primary)
                .disableAutocorrection(true)
                .autocapitalization(.none)
            }
            .padding(8)
            .background(Color(.systemGray5))
            .cornerRadius(10)
            .padding(.horizontal)

            if isEditing {
                Button("Cancel") {
                    withAnimation(.easeOut(duration: 0.1)) {
                        isEditing = false
                        searchText = ""
                        hideKeyboard()
                    }
                }
                .foregroundColor(.orange)
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
                .animation(.easeInOut(duration: 0.2), value: isEditing)
            }
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
