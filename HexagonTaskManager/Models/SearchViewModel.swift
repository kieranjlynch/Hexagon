import Foundation
import CoreData

class SearchViewModel: ObservableObject {
    @Published var searchText: String = "" {
        didSet {
            performSearch()
        }
    }
    
    @Published var searchSuggestions: [String] = []
    @Published var searchScopes: [String] = ["All", "Today", "Scheduled"]
    @Published var selectedSearchScope: String = "All" {
        didSet {
            performSearch()
        }
    }
    
    @Published var searchTokens: [SearchToken] = []
    
    private var viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        performSearch() 
    }
    
    func fetchRequest() -> NSFetchRequest<Reminder> {
        let request: NSFetchRequest<Reminder>
        
        switch selectedSearchScope {
        case "Today":
            request = ReminderService.remindersByStatType(statType: .today)
        case "Scheduled":
            request = ReminderService.remindersByStatType(statType: .scheduled)
        default:
            request = ReminderService.getRemindersBySearchTerm(searchText)
        }
        
        if !searchTokens.isEmpty {
            let tokenPredicate = NSPredicate(format: "title IN %@", searchTokens.map { $0.name })
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [request.predicate!, tokenPredicate])
        }
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.title, ascending: true)]
        
        return request
    }
    
    var searchResults: [Reminder] {
        let request = fetchRequest()
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Fetch failed: \(error.localizedDescription)")
            return []
        }
    }
    
    func performSearch() {
        objectWillChange.send()
    }
    
    func updateReminder(_ reminder: Reminder) {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save reminder: \(error)")
        }
    }
}
