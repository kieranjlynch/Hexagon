import SwiftUI
import CoreData

struct HomeView: View {
    @FetchRequest(fetchRequest: ReminderService.getUnassignedAndIncompleteReminders())
    private var unassignedReminders: FetchedResults<Reminder>
    
    @FetchRequest(fetchRequest: ReminderService.remindersByStatType(statType: .today))
    private var todayResults: FetchedResults<Reminder>
    
    @FetchRequest(fetchRequest: ReminderService.remindersByStatType(statType: .scheduled))
    private var scheduledResults: FetchedResults<Reminder>
    
    @FetchRequest(fetchRequest: ReminderService.remindersByStatType(statType: .all))
    private var allResults: FetchedResults<Reminder>
    
    @FetchRequest(fetchRequest: ReminderService.remindersByStatType(statType: .completed))
    private var completedResults: FetchedResults<Reminder>
    
    @FetchRequest(sortDescriptors: [])
    private var myListResults: FetchedResults<TaskList>
    
    @State private var search: String = ""
    @State private var isPresented: Bool = false
    @State private var searching: Bool = false
    private var ReminderCounts = ReminderStats()
    @State private var reminderStatsValues = ReminderStatsValues()
    
    @State private var selectedTab: String = "Lists"
    @State private var selectedListID: NSManagedObjectID?
    
    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.darkGray)
        
        let tabBarItemAppearance = UITabBarItemAppearance()
        tabBarItemAppearance.normal.iconColor = UIColor(Color.offWhite)
        tabBarItemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.offWhite)]
        
        tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(Color.darkGray)
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SearchView(context: CoreDataProvider.shared.persistentContainer.viewContext)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag("Search")
            
            FiltersView()
                .tabItem {
                    Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                }
                .tag("Filters")
            
            AvailableView()
                .tabItem {
                    Label("Available", systemImage: "tray")
                }
                .tag("Available")
            
            ListsView(selectedListID: $selectedListID)
                .tabItem {
                    Label("Lists", systemImage: "list.bullet")
                }
                .tag("Lists")
        }
        .accentColor(.orange)
        .onAppear {
            reminderStatsValues = ReminderCounts.build(myListResults: myListResults)
        }
        .onChange(of: selectedTab) {
            if selectedTab != "Lists" {
                selectedListID = nil
            }
        }
    }
}
