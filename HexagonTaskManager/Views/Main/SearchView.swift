import SwiftUI
import CoreData

struct SearchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var viewModel: SearchViewModel
    @FocusState private var isSearchFocused: Bool
    @State private var searchText = ""
    @State private var showingAddReminder = false
    @State private var showingAddList = false
    @State private var selectedReminder: Reminder?
    @State private var showSettingsView = false
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(context: context))
    }
    
    var filteredReminders: [Reminder] {
        viewModel.searchResults.filter { reminder in
            reminder.title?.localizedStandardContains(searchText) ?? false
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(filteredReminders, id: \.self) { reminder in
                        Text(reminder.title ?? "Untitled")
                            .background(Color.customBackgroundColor)
                            .foregroundColor(.offWhite)
                            .listRowBackground(Color.customBackgroundColor)
                            .onTapGesture {
                                selectedReminder = reminder
                            }
                    }
                }
                .background(Color.darkGray.ignoresSafeArea())
                .searchable(text: $searchText, prompt: "Search")
                .focused($isSearchFocused)
                .onChange(of: searchText) { _, newValue in
                    viewModel.searchText = newValue
                    viewModel.performSearch()
                }
                .onChange(of: viewModel.selectedSearchScope) {
                    viewModel.performSearch()
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
            .navigationTitle("Search")
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
                        try ReminderService.saveTaskList(name, color, symbol)
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
        guard let index = viewModel.searchResults.firstIndex(where: { $0 == reminder }) else {
            fatalError("Reminder not found")
        }
        
        return Binding(
            get: { viewModel.searchResults[index] },
            set: { newValue in
                viewModel.updateReminder(newValue)
            }
        )
    }
}
