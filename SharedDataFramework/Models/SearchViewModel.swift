import Foundation
import CoreData

public class SearchViewModel: ObservableObject {
    @Published public var searchText: String = "" {
        didSet {
            performSearch()
        }
    }

    @Published public var searchSuggestions: [String] = []
    @Published public var searchScopes: [String] = ["All", "Today", "Scheduled"]
    @Published public var selectedSearchScope: String = "All" {
        didSet {
            performSearch()
        }
    }
    
    @Published public var searchTokens: [SearchToken] = []
    
    private var viewContext: NSManagedObjectContext
    private let reminderService = ReminderService()
    
    public init(context: NSManagedObjectContext) {
        self.viewContext = context
        performSearch()
    }
    
    public func fetchRequest() -> NSFetchRequest<Reminder> {
        let request: NSFetchRequest<Reminder>
        
        switch selectedSearchScope {
        case "Today":
            request = reminderService.remindersByStatType(statType: .today)
        case "Scheduled":
            request = reminderService.remindersByStatType(statType: .scheduled)
        default:
            request = reminderService.getRemindersBySearchTerm(searchText)
        }
        
        if !searchTokens.isEmpty {
            let tokenPredicate = NSPredicate(format: "title IN %@", searchTokens.map { $0.name })
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [request.predicate!, tokenPredicate])
        }
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.title, ascending: true)]
        
        return request
    }
    
    public var searchResults: [Reminder] {
        let request = fetchRequest()
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Fetch failed: \(error.localizedDescription)")
            return []
        }
    }
    
    public func performSearch() {
        objectWillChange.send()
    }
    
    public func updateReminder(_ reminder: Reminder) {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save reminder: \(error)")
        }
    }
}
