//
//  SearchViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI
import CoreData
import HexagonData

@MainActor
public class SearchViewModel: ObservableObject {
    @Published public var searchText: String = ""
    @Published public var selectedReminder: Reminder?
    @Published public var showingAdvancedSearchView = false
    @Published public var selectedSavedSearch: SavedFilter?
    @Published public var searchResults: [Reminder] = []
    @Published public var filterItems: [FilterItem] = []
    @Published public var savedFilters: [SavedFilter] = []
    @Published public var selectedSearchScope: String = "All"
    
    private let initialSavedSearch: SavedFilter?
    private var reminderService: ReminderService?
    private var viewContext: NSManagedObjectContext?
    
    public init(initialSavedSearch: SavedFilter? = nil) {
        self.initialSavedSearch = initialSavedSearch
    }
    
    public func setup(reminderService: ReminderService, viewContext: NSManagedObjectContext) {
        self.reminderService = reminderService
        self.viewContext = viewContext
        Task { await loadInitialSearchData() }
    }
    
    public func performSearch() async {
        guard let viewContext = viewContext else { return }
        do {
            let predicate = self.buildSearchPredicate()
            let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
            request.predicate = predicate
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.title, ascending: true)]
            
            let fetchedReminders = try viewContext.fetch(request)
            self.searchResults = fetchedReminders
        } catch {
            self.searchResults = []
        }
    }
    
    private func buildSearchPredicate() -> NSPredicate {
        var predicates: [NSPredicate] = []
        
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            predicates.append(NSPredicate(format: "title CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", searchText, searchText))
        }
        
        for item in filterItems {
            switch item.criteria {
            case .quote, .wildcard:
                if let value = item.value {
                    predicates.append(NSPredicate(format: "title CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", value, value))
                }
            case .tag:
                if let value = item.value {
                    predicates.append(NSPredicate(format: "ANY tags.name ==[cd] %@", value))
                }
            case .before:
                if let date = item.date {
                    predicates.append(NSPredicate(format: "endDate <= %@", date as NSDate))
                }
            case .after:
                if let date = item.date {
                    predicates.append(NSPredicate(format: "startDate >= %@", date as NSDate))
                }
            case .priority:
                if let value = item.value, let priority = Int16(value) {
                    predicates.append(NSPredicate(format: "priority == %d", priority))
                }
            case .link:
                predicates.append(NSPredicate(format: "url != nil AND url != ''"))
            case .notifications:
                predicates.append(NSPredicate(format: "notifications != nil AND notifications != ''"))
            case .location:
                predicates.append(NSPredicate(format: "location != nil"))
            case .notes:
                predicates.append(NSPredicate(format: "notes != nil AND notes != ''"))
            case .photos:
                predicates.append(NSPredicate(format: "photos.@count > 0"))
            }
        }
        
        if predicates.isEmpty {
            return NSPredicate(value: true)
        } else {
            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
    }
    
    public func loadSavedFilters() async {
        if let data = UserDefaults.standard.data(forKey: "SavedFilters") {
            do {
                savedFilters = try JSONDecoder().decode([SavedFilter].self, from: data)
            } catch {
                savedFilters = []
            }
        }
    }
    
    public func loadSavedFilter(_ filter: SavedFilter) async {
        filterItems = filter.items
        selectedSavedSearch = filter
        await performSearch()
    }
    
    public func saveCurrentFilter(name: String) {
        Task {
            let newFilter = SavedFilter(name: name, items: filterItems)
            savedFilters.append(newFilter)
            await saveSavedFilters()
        }
    }
    
    public func saveSavedFilters() async {
        do {
            let encoded = try JSONEncoder().encode(savedFilters)
            UserDefaults.standard.set(encoded, forKey: "SavedFilters")
        } catch {
        }
    }
    
    public func toggleCompletion(for reminder: Reminder) {
        guard let reminderService = reminderService else { return }
        Task {
            do {
                try await reminderService.updateReminderCompletionStatus(reminder: reminder, isCompleted: !reminder.isCompleted)
                await performSearch()
            } catch {
            }
        }
    }
    
    public func deleteReminder(_ reminder: Reminder) {
        guard let reminderService = reminderService else { return }
        Task {
            do {
                try await reminderService.deleteReminder(reminder)
                await performSearch()
            } catch {
            }
        }
    }
    
    public func clearSearch() async {
        selectedSavedSearch = nil
        searchText = ""
        filterItems.removeAll()
        selectedSearchScope = "All"
        await performSearch()
    }
    
    private func loadInitialSearchData() async {
        await performSearch()
        await loadSavedFilters()
        if let initialSearch = initialSavedSearch {
            await loadSavedFilter(initialSearch)
        }
    }
}
