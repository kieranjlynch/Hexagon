import SwiftUI

enum ReminderCellEvents {
    case onInfo
    case onCheckedChange(Reminder, Bool)
    case onSelect(Reminder)
    case onTap(Reminder)
    case onDelete(Reminder)
    case onSchedule(Reminder)
}

struct ReminderCellView: View {
    let reminder: Reminder
    let delay = Delay()
    let isSelected: Bool
    @State private var checked: Bool = false
    let onEvent: (ReminderCellEvents) -> Void
    
    private func formatDate(_ date: Date) -> String {
        if date.isToday {
            return "Today"
        } else if date.isTomorrow {
            return "Tomorrow"
        } else {
            return date.formatted(date: .numeric, time: .omitted)
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: checked ? "circle.inset.filled" : "circle")
                .font(.title2)
                .foregroundColor(.offWhite)
                .opacity(0.4)
                .onTapGesture {
                    checked.toggle()
                    delay.cancel()
                    delay.performWork {
                        onEvent(.onCheckedChange(reminder, checked))
                    }
                }
            
            VStack(alignment: .leading) {
                Text(reminder.title ?? "")
                    .foregroundColor(.offWhite)
                if let notes = reminder.notes, !notes.isEmpty {
                    Text(notes)
                        .foregroundColor(.offWhite)
                        .opacity(0.4)
                        .font(.caption)
                }
                
                HStack {
                    if let endDate = reminder.endDate {
                        Text(formatDate(endDate))
                            .foregroundColor(.offWhite)
                    }
                    if let reminderTime = reminder.reminderTime {
                        Text(reminderTime.formatted(date: .omitted, time: .shortened))
                            .foregroundColor(.offWhite)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.caption)
                .opacity(0.4)
            }
            
            Spacer()
            Image(systemName: "info.circle.fill")
                .foregroundColor(.offWhite)
                .opacity(isSelected ? 1.0 : 0.0)
                .onTapGesture {
                    onEvent(.onInfo)
                }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.customBackgroundColor))
        .onAppear {
            checked = reminder.isCompleted
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onEvent(.onTap(reminder))
        }
        .contextMenu {
            Button(role: .destructive) {
                onEvent(.onDelete(reminder))
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                onEvent(.onSchedule(reminder))
            } label: {
                Label("Schedule", systemImage: "calendar")
            }
        }
    }
}
