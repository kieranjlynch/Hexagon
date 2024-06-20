import SwiftUI

struct ListIconView: View {
    let taskList: TaskList
    let onDelete: (TaskList) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: taskList.symbol ?? "list.bullet")
                .foregroundColor(Color(taskList.color ?? .orange))
            Text(taskList.name ?? "")
                .foregroundColor(.offWhite)
            Spacer()
            Text("\(taskList.reminders?.count ?? 0)")
                .foregroundColor(.offWhite)
                .padding(.trailing)
        }
        .contentShape(Rectangle())
        .onLongPressGesture {
            onDelete(taskList)
        }
    }
}
