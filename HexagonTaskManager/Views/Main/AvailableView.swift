import SwiftUI
import SharedDataFramework

struct AvailableView: View {
    private let reminderService = ReminderService() 

    @FetchRequest(fetchRequest: ReminderService().getAvailableTasks())
    private var availableReminders: FetchedResults<Reminder>
    
    @State private var showingAddList = false
    @State private var showingAddReminder = false
    @State private var selectedReminder: Reminder?
    @Environment(\.managedObjectContext) var viewContext
    @State private var showSettingsView = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if availableReminders.isEmpty {
                    Text("No available tasks")
                        .foregroundColor(.gray)
                } else {
                    List(availableReminders) { reminder in
                        ReminderCellView(reminder: reminder, isSelected: false) { event in
                            switch event {
                            case .onInfo:
                                selectedReminder = reminder
                            case .onSelect(let selectedReminder):
                                self.selectedReminder = selectedReminder
                            case .onCheckedChange:
                                viewContext.refreshAllObjects()
                            case .onTap:
                                selectedReminder = reminder
                            case .onDelete(let reminder):
                                selectedReminder = reminder
                            case .onSchedule(let reminder):
                                selectedReminder = reminder
                            }
                        }
                        .listRowBackground(Color.darkGray)
                    }
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    HexagonButtonView(symbol: "plus", action: {
                        showingAddReminder = true
                    })
                    .frame(width: 60, height: 60)
                    .foregroundColor(.orange)
                    
                    HexagonButtonView(symbol: "list.bullet", action: {
                        showingAddList = true
                    })
                    .frame(width: 60, height: 60)
                    .foregroundColor(.orange)
                }
                .padding(.trailing, 30)
                .padding(.bottom, 20)
            }
            .navigationTitle("Available")
            .scrollContentBackground(.hidden)
            .toolbarBackground(Color.darkGray, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .background(Color.darkGray.ignoresSafeArea())
            .sheet(isPresented: $showingAddReminder) {
                AddReminderView()
            }
            .sheet(isPresented: $showingAddList) {
                AddNewListView { name, color, symbol in
                    do {
                        try reminderService.saveTaskList(name, color, symbol)
                    } catch {
                        print("Failed to save new list: \(error)")
                    }
                }
            }
            .sheet(item: $selectedReminder) { reminder in
                EditReminderView(reminder: reminder)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showSettingsView = true
                    }) {
                        Image(systemName: "gear")
                            .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $showSettingsView) {
                SettingsView()
            }
        }
    }
    
    private func binding(for reminder: Reminder) -> Binding<Reminder> {
        guard let index = availableReminders.firstIndex(where: { $0 == reminder }) else {
            fatalError("Reminder not found")
        }
        
        return Binding(
            get: { availableReminders[index] },
            set: { newValue in
                if let index = availableReminders.firstIndex(where: { $0 == reminder }) {
                    let updatedReminder = availableReminders[index]
                    updatedReminder.title = newValue.title
                    updatedReminder.notes = newValue.notes
                    do {
                        try viewContext.save()
                    } catch {
                        print("Failed to update reminder: \(error)")
                    }
                }
            }
        )
    }
}
