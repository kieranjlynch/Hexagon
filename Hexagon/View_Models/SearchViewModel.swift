//
//  SearchViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import Foundation
import SwiftUI
import CoreData
import Combine
import os

struct PredicateWrapper: @unchecked Sendable {
    var predicate: NSPredicate
}

struct SearchState: Equatable {
    var searchText: String = ""
    var tokens: [ReminderToken] = []
    var selectedReminder: Reminder?
    var searchResults: [Reminder] = []
    
    static func == (lhs: SearchState, rhs: SearchState) -> Bool {
        lhs.searchText == rhs.searchText &&
        lhs.tokens == rhs.tokens &&
        lhs.searchResults.count == rhs.searchResults.count
    }
}


@MainActor
final class SearchViewModel: ObservableObject, ViewModel {
    // MARK: - Published Properties
    @Published private(set) var viewState: ViewState<SearchState>
    @Published var error: IdentifiableError?
    
    // MARK: - ViewModel Protocol Properties
    var activeTasks = Set<Task<Void, Never>>()
    var cancellables = Set<AnyCancellable>()
    
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "SearchViewModel")
    
    private let searchDataProvider: SearchDataProvider
    private let resultsDebounceInterval: TimeInterval
    private var basePredicate: PredicateWrapper?
    private var isSearching = false
    private var isInitialSearch = true
    private var lastSearchTime = Date.distantPast
    private var lastStateUpdate = Date()
    private let minimumSearchInterval: TimeInterval = 0.5
    private let minimumStateInterval: TimeInterval = 0.1
    
    init(
        searchDataProvider: SearchDataProvider,
        resultsDebounceInterval: TimeInterval = 0.3
    ) {
        self.searchDataProvider = searchDataProvider
        self.resultsDebounceInterval = resultsDebounceInterval
        self.viewState = .idle
        setupSearchSubscription()
    }
    
    func viewDidLoad() { }
    
    func viewWillAppear() { }
    
    func viewWillDisappear() { }
    
    // MARK: - Data Loading
    func loadContent() async throws -> [Reminder] {
        guard case .loaded(let state) = viewState else { return [] }
        return try await searchDataProvider.performSearch(
            text: state.searchText,
            tokens: state.tokens,
            basePredicate: basePredicate
        )
    }
    
    func handleLoadedContent(_ results: [Reminder]) {
        updateState { state in
            state.searchResults = results
        }
        viewState = results.isEmpty ? .noResults : .results(getState())
    }
    
    func handleLoadError(_ error: Error) {
        self.error = IdentifiableError(error: error)
        viewState = .error(error.localizedDescription)
        logger.error("Search failed: \(error.localizedDescription)")
    }
    
    // MARK: - State Management
    private func updateState(_ update: (inout SearchState) -> Void) {
        var newState = getState()
        update(&newState)
        viewState = .loaded(newState)
    }
    
    private func getState() -> SearchState {
        guard case .loaded(let state) = viewState else {
            return SearchState()
        }
        return state
    }
    
    // MARK: - Search Operations
    func updateSearchText(_ text: String) {
        updateState { state in
            state.searchText = text
        }
    }
    
    func updateBasePredicate(_ predicate: NSPredicate) async {
        guard basePredicate?.predicate != predicate else { return }
        basePredicate = PredicateWrapper(predicate: predicate)
        if isInitialSearch {
            isInitialSearch = false
            await performInitialSearch()
        } else {
            await performSearch()
        }
    }
    
    func clearSearch() {
        viewState = .loaded(SearchState())
    }
    
    func selectReminder(_ reminder: Reminder?) {
        updateState { state in
            state.selectedReminder = reminder
        }
    }
    
    func updateTokens(_ tokens: [ReminderToken]) {
        updateState { state in
            state.tokens = tokens
        }
    }
    
    // MARK: - Private Methods
    private func setupSearchSubscription() {
        $viewState
            .compactMap { viewState -> (String, [ReminderToken])? in
                guard case .loaded(let state) = viewState else { return nil }
                return (state.searchText, state.tokens)
            }
            .debounce(for: .seconds(resultsDebounceInterval), scheduler: DispatchQueue.main)
            .removeDuplicates { prev, current in
                prev.0 == current.0 && prev.1 == current.1
            }
            .sink { [weak self] _, _ in
                guard let self = self,
                      !self.isSearching,
                      !self.isInitialSearch,
                      Date().timeIntervalSince(self.lastSearchTime) >= self.minimumSearchInterval
                else { return }
                
                Task { @MainActor [weak self] in
                    await self?.performSearch()
                }
            }
            .store(in: &cancellables)
    }
    
    private func performInitialSearch() async {
        guard !Task.isCancelled else { return }
        viewState = .loaded(SearchState())
        
        do {
            let results = try await loadContent()
            handleLoadedContent(results)
        } catch {
            handleLoadError(error)
        }
    }
    
    private func performSearch() async {
        guard !Task.isCancelled && !isSearching else { return }
        
        lastSearchTime = Date()
        isSearching = true
        viewState = .searching
        
        do {
            let results = try await loadContent()
            handleLoadedContent(results)
        } catch {
            handleLoadError(error)
        }
        
        isSearching = false
    }
}

// MARK: - Search Protocols
@MainActor
public protocol SearchResultsPresenting {
    var searchResults: [Reminder] { get }
    var selectedReminder: Reminder? { get }
    var tokens: [ReminderToken] { get }
    func updateResults(_ results: [Reminder])
}

// MARK: - SearchResultsPresenting
extension SearchViewModel: SearchResultsPresenting {
    var searchResults: [Reminder] {
        guard case .loaded(let state) = viewState else { return [] }
        return state.searchResults
    }
    
    var selectedReminder: Reminder? {
        guard case .loaded(let state) = viewState else { return nil }
        return state.selectedReminder
    }
    
    var tokens: [ReminderToken] {
        guard case .loaded(let state) = viewState else { return [] }
        return state.tokens
    }
    
    func updateResults(_ results: [Reminder]) {
        updateState { state in
            state.searchResults = results
        }
    }
}

// MARK: - Error Types
extension SearchViewModel {
    enum SearchError: LocalizedError {
        case invalidFilterName
        case searchFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidFilterName:
                return "Filter name cannot be empty"
            case .searchFailed(let error):
                return "Search operation failed: \(error.localizedDescription)"
            }
        }
    }
}
