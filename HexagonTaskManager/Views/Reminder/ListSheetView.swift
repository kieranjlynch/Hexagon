import SwiftUI
import SharedDataFramework

struct ListSheetView: View {
    var lists: FetchedResults<TaskList>
    @Binding var selectedList: TaskList?
    
    var body: some View {
        Form {
            Picker("List", selection: $selectedList) {
                Text("None").tag(nil as TaskList?)
                ForEach(lists) { list in
                    Text(list.name ?? "").tag(list as TaskList?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .tint(.orange)
        }
        .listRowBackground(Color.customBackgroundColor)
        .environment(\.colorScheme, .dark)
    }
}
