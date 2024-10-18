//
//  SearchViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI
import Combine
import HexagonData
import CoreData

@MainActor
public class SearchViewModel: ObservableObject {
    @Published public var searchText: String = ""
    @Published public var searchResults: [Reminder] = []
    
    private var reminderService: ReminderService?
    private var viewContext: NSManagedObjectContext?
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        setupSearchTextBinding()
    }
    
    public func setup(reminderService: ReminderService, viewContext: NSManagedObjectContext) {
        self.reminderService = reminderService
        self.viewContext = viewContext
    }
    
    // MARK: - Combine Binding for Search Text
    
    private func setupSearchTextBinding() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                Task {
                    await self?.performSearch()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Async/Await for Performing Search
    
    public func performSearch() async {
        guard let viewContext = viewContext, !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        do {
            let predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", searchText, searchText)
            let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
            request.predicate = predicate
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.title, ascending: true)]
            
            let fetchedReminders = try viewContext.fetch(request)
            self.searchResults = fetchedReminders
        } catch {
            self.searchResults = []
        }
    }
}
