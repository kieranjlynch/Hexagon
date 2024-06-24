import SwiftUI
import CoreData
import SharedDataFramework

struct ListDetailView: View {
    @ObservedObject var taskList: TaskList
    @FetchRequest var reminders: FetchedResults<Reminder>
    @State private var selectedReminder: Reminder?
    @State private var showEditReminderView = false
    
    @Binding var selectedListID: NSManagedObjectID?
    
    init(taskList: TaskList, selectedListID: Binding<NSManagedObjectID?>) {
        self.taskList = taskList
        _reminders = FetchRequest<Reminder>(
            entity: Reminder.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Reminder.title, ascending: true)],
            predicate: NSPredicate(format: "list == %@", taskList)
        )
        self._selectedListID = selectedListID
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(reminders) { reminder in
                    ReminderCellView(reminder: reminder, isSelected: false) { event in
                        switch event {
                        case .onTap(let reminder):
                            self.selectedReminder = reminder
                            self.showEditReminderView = true
                        default:
                            break
                        }
                    }
                    .listRowBackground(Color.clear)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.customBackgroundColor))
                    .padding(.vertical, 1)
                }
                .onMove(perform: moveReminder)
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.darkGray.ignoresSafeArea())
        .foregroundColor(.offWhite)
        .scrollContentBackground(.hidden)
        .sheet(isPresented: $showEditReminderView) {
            if let reminder = selectedReminder {
                EditReminderView(reminder: reminder)
            }
        }
        .navigationTitle(taskList.name!)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.darkGray.ignoresSafeArea())
        .onAppear {
            selectedListID = taskList.objectID
        }
    }
    
}

private func moveReminder(from source: IndexSet, to destination: Int) {
    // I neede to implement the logic to reorder reminders within a list
}
