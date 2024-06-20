import SwiftUI

struct TagsSheetView: View {
    var tags: FetchedResults<Tag>
    @Binding var selectedTag: Tag?
    
    var body: some View {
        Form {
            Picker("Tags", selection: $selectedTag) {
                Text("None").tag(nil as Tag?)
                ForEach(tags) { tag in
                    Text(tag.name ?? "").tag(tag as Tag?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .tint(.orange)
        }
        .listRowBackground(Color.customBackgroundColor)
        .environment(\.colorScheme, .dark)
    }
}
