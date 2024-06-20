import SwiftUI

struct ReminderListView: View {
    
    let reminders: [Reminder]
    let filterName: String
    @State private var selectedReminder: Reminder?
    @State private var showReminderDetail: Bool = false
    @State private var showTaskScheduleView = false
    
    private func reminderCheckedChanged(reminder: Reminder, isCompleted: Bool) {
        var editConfig = ReminderEditConfig(reminder: reminder)
        editConfig.isCompleted = isCompleted
        
        do {
            let _ = try ReminderService.updateReminder(reminder: reminder, editConfig: editConfig)
        } catch {
            print(error)
        }
    }
    
    private func isReminderSelected(_ reminder: Reminder) -> Bool {
        selectedReminder?.objectID == reminder.objectID
    }
    
    private func deleteReminder(_ reminder: Reminder) {
        do {
            try ReminderService.deleteReminder(reminder)
        } catch {
            print(error)
        }
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(reminders) { reminder in
                    ReminderCellView(
                        reminder: reminder,
                        isSelected: isReminderSelected(reminder),
                        onEvent: handleCellEvent
                    )
                    .listRowBackground(Color.darkGray)
                }
            }
            .background(Color.darkGray)
            .scrollContentBackground(.hidden)
            .sheet(isPresented: $showReminderDetail) {
                if let reminder = selectedReminder {
                    EditReminderView(reminder: reminder)
                }
            }
            .background(Color.darkGray)
            .foregroundColor(.offWhite)
            .navigationTitle(filterName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.darkGray, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showTaskScheduleView) {
            if let reminder = selectedReminder {
                TaskScheduleView(task: reminder.title ?? "")
            }
        }
    }
    
    private func handleCellEvent(_ event: ReminderCellEvents) {
        switch event {
        case .onInfo:
            showReminderDetail = true
        case .onSelect(let reminder):
            selectedReminder = reminder
        case .onCheckedChange(let reminder, let isCompleted):
            reminderCheckedChanged(reminder: reminder, isCompleted: isCompleted)
        case .onTap(let reminder):
            selectedReminder = reminder
        case .onDelete(let reminder):
            deleteReminder(reminder)
        case .onSchedule(let reminder):
            selectedReminder = reminder
            showTaskScheduleView = true
        }
    }
}
