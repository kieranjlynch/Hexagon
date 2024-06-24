import SwiftUI
import CoreData
import SharedDataFramework

struct ListsView: View {
    @FetchRequest(
        entity: TaskList.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskList.order, ascending: true)]
    )
    var taskLists: FetchedResults<TaskList>
    
    private var reminderService = ReminderService()
    
    @FetchRequest(fetchRequest: ReminderService().getUnassignedReminders())
    var unassignedReminders: FetchedResults<Reminder>
    
    @State private var taskListArray: [TaskList] = []
    @State private var showTaskScheduleView = false
    @State private var showingAlert = false
    @State private var listToDelete: TaskList?
    @State private var showingAddReminder = false
    @State private var showingAddList = false
    @State private var selectedReminder: Reminder?
    @State private var showSettingsView = false
    @State private var selectedReminderForSchedule: Reminder?
    @Binding var selectedListID: NSManagedObjectID?
    
    public init(selectedListID: Binding<NSManagedObjectID?>) {
            self._selectedListID = selectedListID
        }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                List {
                    ForEach(taskListArray) { taskList in
                        NavigationLink(destination: ListDetailView(taskList: taskList, selectedListID: $selectedListID)) {
                            HStack {
                                ListIconView(taskList: taskList, onDelete: { list in
                                    listToDelete = list
                                    showingAlert = true
                                })
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                    }
                    .onDelete(perform: { indexSet in
                        if let index = indexSet.first {
                            listToDelete = taskListArray[index]
                            showingAlert = true
                        }
                    })
                    .onMove(perform: moveList)
                    .alert(isPresented: $showingAlert) {
                        Alert(
                            title: Text("Delete List"),
                            message: Text("Are you sure you want to delete this list and all its tasks?"),
                            primaryButton: .destructive(Text("Delete")) {
                                if let list = listToDelete {
                                    deleteList(list)
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    .listRowBackground(Color.customBackgroundColor)
                }
                .frame(maxHeight: .infinity)
                .padding(.top, 0.5)
                .listRowSpacing(16.0)
                
                Divider()
                
                VStack(alignment: .leading) {
                    Text("Unassigned Tasks")
                        .font(.headline)
                        .padding([.leading, .top])
                        .foregroundColor(.offWhite)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(unassignedReminders) { reminder in
                                ReminderCellView(reminder: reminder, isSelected: false) { event in
                                    switch event {
                                    case .onInfo:
                                        selectedReminder = reminder
                                    case .onSelect(let selectedReminder):
                                        self.selectedReminder = selectedReminder
                                    case .onCheckedChange:
                                        CoreDataProvider.shared.persistentContainer.viewContext.refreshAllObjects()
                                    case .onTap(let reminder):
                                        selectedReminder = reminder
                                    case .onDelete(let reminder):
                                        deleteReminder(reminder)
                                    case .onSchedule(let reminder):
                                        selectedReminder = reminder
                                        showTaskScheduleView = true
                                    }
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteReminder(reminder)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        selectedReminderForSchedule = reminder
                                        showTaskScheduleView = true
                                    } label: {
                                        Label("Schedule", systemImage: "calendar")
                                    }
                                }
                            }
                            .sheet(isPresented: $showTaskScheduleView) {
                                if let reminder = selectedReminderForSchedule {
                                    TaskScheduleView(task: reminder.title ?? "")
                                }
                            }
                        }
                    }
                    .padding(.leading)
                }
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
            .frame(maxHeight: .infinity)
            .navigationTitle("Lists")
            .scrollContentBackground(.hidden)
            .background(Color.darkGray.ignoresSafeArea())
            .toolbarBackground(Color.darkGray, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
        .sheet(isPresented: $showingAddReminder) {
            AddReminderView()
        }
        .sheet(isPresented: $showingAddList) {
            AddNewListView { name, color, symbol in
                do {
                    try reminderService.saveTaskList(name, color, symbol)
                    refreshTaskLists()
                } catch {
                    print("Failed to save new list: \(error)")
                }
            }
        }
        .sheet(item: $selectedReminder) { reminder in
            EditReminderView(reminder: reminder)
        }
        .onAppear {
            taskListArray = Array(taskLists)
            if let selectedListID = selectedListID, let selectedList = taskLists.first(where: { $0.objectID == selectedListID }) {
                if let index = taskListArray.firstIndex(of: selectedList) {
                    let indexSet = IndexSet(integer: index)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            taskListArray.move(fromOffsets: indexSet, toOffset: 0)
                        }
                    }
                }
            }
        }
    }
    
    private func moveList(from source: IndexSet, to destination: Int) {
        taskListArray.move(fromOffsets: source, toOffset: destination)
        saveTaskListOrder()
    }
    
    private func saveTaskListOrder() {
        let context = CoreDataProvider.shared.persistentContainer.viewContext
        for (index, taskList) in taskListArray.enumerated() {
            taskList.order = Int16(index)
        }
        do {
            try context.save()
        } catch {
            print("Failed to save task list order: \(error)")
        }
    }
    
    private func refreshTaskLists() {
        taskListArray = Array(taskLists)
    }
}

private func deleteList(_ list: TaskList) {
    let context = CoreDataProvider.shared.persistentContainer.viewContext
    context.delete(list)
    do {
        try context.save()
    } catch {
        print("Failed to delete list: \(error)")
    }
}

private func deleteReminder(_ reminder: Reminder) {
    let context = CoreDataProvider.shared.persistentContainer.viewContext
    context.delete(reminder)
    do {
        try context.save()
    } catch {
        print("Failed to delete reminder: \(error)")
    }
}
