import SwiftUI

struct FiltersView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \TaskList.name, ascending: true)])
    private var myListResults: FetchedResults<TaskList>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Reminder.title, ascending: true)])
    private var searchResults: FetchedResults<Reminder>
    
    @FetchRequest(fetchRequest: ReminderService.remindersByStatType(statType: .today))
    private var todayResults: FetchedResults<Reminder>
    
    @FetchRequest(fetchRequest: ReminderService.remindersByStatType(statType: .scheduled))
    private var scheduledResults: FetchedResults<Reminder>
    
    @FetchRequest(fetchRequest: ReminderService.remindersByStatType(statType: .all))
    private var allResults: FetchedResults<Reminder>
    
    @FetchRequest(fetchRequest: ReminderService.remindersByStatType(statType: .completed))
    private var completedResults: FetchedResults<Reminder>
    
    @FetchRequest(fetchRequest: ReminderService.remindersByStatType(statType: .withNotes))
    private var withNotesResults: FetchedResults<Reminder>
    
    @FetchRequest(fetchRequest: ReminderService.remindersByStatType(statType: .withURL))
    private var withURLResults: FetchedResults<Reminder>
    
    @FetchRequest(fetchRequest: ReminderService.remindersByStatType(statType: .withPriority))
    private var withPriorityResults: FetchedResults<Reminder>
    
    @FetchRequest(fetchRequest: ReminderService.remindersByStatType(statType: .withTag))
    private var withTagResults: FetchedResults<Reminder>
    
    @FetchRequest(fetchRequest: ReminderService.remindersByStatType(statType: .overdue))
    private var overdueResults: FetchedResults<Reminder>
    
    @FetchRequest(fetchRequest: ReminderService.remindersByStatType(statType: .withLocation))
    private var withLocationResults: FetchedResults<Reminder>
    
    @State private var search: String = ""
    @State private var isPresented: Bool = false
    @State private var searching: Bool = false
    @State private var showingAddReminder = false
    @State private var showingAddList = false
    @State private var showSettingsView = false
    
    private var reminderStatsBuilder = ReminderStats()
    @State private var reminderStatsValues = ReminderStatsValues()
    
    private let cornerRadius: CGFloat = 10
    
    @SceneStorage("FiltersView.selectedFilter") private var selectedFilter: String?

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkGray.ignoresSafeArea()
                VStack {
                    if isIPad {
                        iPadLayout
                    } else {
                        iPhoneLayout
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
                    .padding(.top, 20)
                }
                .background(Color.darkGray)
                .navigationTitle("Filters")
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
        }
        .sheet(isPresented: $isPresented) {
            AddReminderView()
        }
        .sheet(isPresented: $showingAddReminder) {
            AddReminderView()
        }
        .sheet(isPresented: $showingAddList) {
            AddNewListView { name, color, symbol in
                do {
                    try ReminderService.saveTaskList(name, color, symbol)
                } catch {
                    print("Failed to save new list: \(error)")
                }
            }
        }
        .onAppear {
            reminderStatsValues = reminderStatsBuilder.build(myListResults: myListResults)
        }
    }
    
    private var iPadLayout: some View {
        ScrollView {
            VStack(spacing: 20) {
                filterCell(for: todayResults, icon: "calendar", title: "Today", count: reminderStatsValues.todayCount)
                filterCell(for: scheduledResults, icon: "calendar.circle.fill", title: "Scheduled", count: reminderStatsValues.scheduledCount, iconColor: .orange)
                filterCell(for: allResults, icon: "tray.circle.fill", title: "All", count: reminderStatsValues.allCount, iconColor: .orange)
                filterCell(for: completedResults, icon: "checkmark.circle.fill", title: "Completed", count: reminderStatsValues.completedCount, iconColor: .orange)
                filterCell(for: withNotesResults, icon: "doc.text", title: "Notes", count: withNotesResults.count, iconColor: .orange)
                filterCell(for: withURLResults, icon: "link.circle.fill", title: "Link", count: withURLResults.count, iconColor: .orange)
                filterCell(for: withPriorityResults, icon: "exclamationmark.circle", title: "Priority", count: withPriorityResults.count, iconColor: .orange)
                filterCell(for: withTagResults, icon: "tag.circle.fill", title: "Tag", count: withTagResults.count, iconColor: .orange)
                filterCell(for: overdueResults, icon: "clock.circle.fill", title: "Overdue", count: overdueResults.count, iconColor: .orange)
                filterCell(for: withLocationResults, icon: "location.circle.fill", title: "Location", count: withLocationResults.count, iconColor: .orange)
            }
            .padding(.horizontal)
        }
        .frame(minWidth: 300)
    }
    
    private var iPhoneLayout: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(stride(from: 0, to: filterCells.count, by: 2)), id: \.self) { index in
                        HStack {
                            if index < filterCells.count {
                                filterCells[index]
                                    .frame(width: (geometry.size.width - 30) / 2)
                            }
                            if index + 1 < filterCells.count {
                                filterCells[index + 1]
                                    .frame(width: (geometry.size.width - 30) / 2)
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
        }
    }
    
    private var filterCells: [AnyView] {
        [
            AnyView(filterCell(for: todayResults, icon: "calendar.circle.fill", title: "Today", count: reminderStatsValues.todayCount)),
            AnyView(filterCell(for: scheduledResults, icon: "calendar.circle.fill", title: "Scheduled", count: reminderStatsValues.scheduledCount, iconColor: .orange)),
            AnyView(filterCell(for: allResults, icon: "tray.circle.fill", title: "All", count: reminderStatsValues.allCount, iconColor: .orange)),
            AnyView(filterCell(for: completedResults, icon: "checkmark.circle.fill", title: "Completed", count: reminderStatsValues.completedCount, iconColor: .orange)),
            AnyView(filterCell(for: withNotesResults, icon: "doc.circle.fill", title: "Notes", count: withNotesResults.count, iconColor: .orange)),
            AnyView(filterCell(for: withURLResults, icon: "link.circle.fill", title: "Link", count: withURLResults.count, iconColor: .orange)),
            AnyView(filterCell(for: withPriorityResults, icon: "exclamationmark.circle.fill", title: "Priority", count: withPriorityResults.count, iconColor: .orange)),
            AnyView(filterCell(for: withTagResults, icon: "tag.circle.fill", title: "Tag", count: withTagResults.count, iconColor: .orange)),
            AnyView(filterCell(for: overdueResults, icon: "clock.circle.fill", title: "Overdue", count: overdueResults.count, iconColor: .orange)),
            AnyView(filterCell(for: withLocationResults, icon: "location.circle.fill", title: "Location", count: withLocationResults.count, iconColor: .orange))
        ]
    }
    
    private func filterCell(for results: FetchedResults<Reminder>, icon: String, title: String, count: Int? = nil, iconColor: Color = .orange) -> some View {
        NavigationLink(destination: ReminderListView(reminders: Array(results), filterName: title)) {
            FilterStatsView(icon: icon, title: title, count: count ?? results.count, iconColor: iconColor)
        }
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.customBackgroundColor)
        )
    }
}
