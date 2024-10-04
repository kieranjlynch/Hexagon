//
//  SearchView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import CoreData
import HexagonData

public struct SavedFilter: Codable, Identifiable {
    public var id = UUID()
    public let name: String
    public let items: [FilterItem]
}

public struct SearchView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject var reminderService: ReminderService
    @EnvironmentObject var locationService: LocationService
    @Environment(\.managedObjectContext) private var viewContext

    @StateObject private var viewModel = SearchViewModel()
    @State private var localSearchText: String = ""
    @State private var localShowingAdvancedSearchView = false

    public var body: some View {
        NavigationStack {
            VStack {
                searchField

                searchControls

                if let selectedSearch = viewModel.selectedSavedSearch {
                    searchSummary(for: selectedSearch)
                }

                List(viewModel.searchResults, id: \.objectID) { reminder in
                    TaskCardView(
                        reminder: reminder,
                        onTap: {
                            Task { @MainActor in
                                viewModel.selectedReminder = reminder
                            }
                        },
                        onToggleCompletion: {
                            Task {
                                viewModel.toggleCompletion(for: reminder)
                            }
                        },
                        selectedDate: Date(),
                        selectedDuration: 60.0
                    )
                    .listRowSeparator(.hidden, edges: .all)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Search")
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .sheet(item: Binding(
                get: { viewModel.selectedReminder },
                set: { newValue in
                    Task { @MainActor in
                        viewModel.selectedReminder = newValue
                    }
                }
            )) { reminder in
                AddReminderView(reminder: reminder)
                    .environmentObject(reminderService)
                    .environmentObject(locationService)
            }
            .onAppear {
                viewModel.setup(reminderService: reminderService, viewContext: viewContext)
                localSearchText = viewModel.searchText
                localShowingAdvancedSearchView = viewModel.showingAdvancedSearchView
            }
        }
    }

    private var searchField: some View {
        TextField("Search", text: $localSearchText)
            .padding(10)
            .background(Color(colorScheme == .dark ? .black : .white))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(colorScheme == .dark ? .gray : .black), lineWidth: 1)
            )
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 6)
            .onChange(of: localSearchText) { _, newValue in
                Task { @MainActor in
                    viewModel.searchText = newValue
                    await viewModel.performSearch()
                }
            }
    }

    private var searchControls: some View {
        HStack(spacing: 16) {
            savedSearchMenu
            advancedSearchButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    private var savedSearchMenu: some View {
        Menu {
            if viewModel.savedFilters.isEmpty {
                Text("No saved searches")
            } else {
                ForEach(viewModel.savedFilters) { filter in
                    Button(filter.name) {
                        Task {
                            await viewModel.loadSavedFilter(filter)
                        }
                    }
                }
            }
        } label: {
            CustomButton(
                title: "Saved Search",
                action: {},
                style: .secondary
            )
        }
    }

    private var advancedSearchButton: some View {
        CustomButton(
            title: "Advanced Search",
            action: {
                localShowingAdvancedSearchView.toggle()
                Task { @MainActor in
                    viewModel.showingAdvancedSearchView = localShowingAdvancedSearchView
                }
            },
            style: .secondary
        )
        .sheet(isPresented: $localShowingAdvancedSearchView) {
            AdvancedSearchView(
                filterItems: Binding(
                    get: { viewModel.filterItems },
                    set: { newValue in
                        Task { @MainActor in
                            viewModel.filterItems = newValue
                        }
                    }
                ),
                onSave: { name in
                    viewModel.saveCurrentFilter(name: name)
                }
            )
        }
    }

    private func searchSummary(for selectedSearch: SavedFilter) -> some View {
        HStack {
            Text("Tasks matching: \(selectedSearch.name)")
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .font(.headline)
            Spacer()
            Button(action: {
                Task {
                    await viewModel.clearSearch()
                    localSearchText = ""
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
}
