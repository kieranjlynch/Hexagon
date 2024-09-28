//
//  AdvancedSearchView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI

struct AdvancedSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var appSettings: AppSettings
    @Binding var filterItems: [FilterItem]
    @State private var newFilterName = ""
    @State private var showingSaveAlert = false
    
    var onSave: (String) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(filterItems.enumerated()), id: \.element.id) { index, item in
                    FilterItemView(
                        item: Binding(
                            get: { self.filterItems[index] },
                            set: { self.filterItems[index] = $0 }
                        ),
                        onRemove: { removeFilterItem(at: index) },
                        onGroup: { groupFilters(at: index) }
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
                }
                
                addButton
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
            
            buttonRow
        }
        .navigationTitle("Advanced Search")
        .alert("Save Filter", isPresented: $showingSaveAlert) {
            TextField("Filter Name", text: $newFilterName)
            Button("Save") {
                onSave(newFilterName)
                newFilterName = ""
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a name for this filter")
        }
    }
    
    private var addButton: some View {
        styledButton(title: "Add Step", style: .secondary, appTintColor: appSettings.appTintColor, action: addFilterItem)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var buttonRow: some View {
        HStack {
            styledButton(title: "Cancel", style: .secondary, appTintColor: appSettings.appTintColor) {
                presentationMode.wrappedValue.dismiss()
            }
            styledButton(title: "Save", style: .primary, appTintColor: appSettings.appTintColor) {
                showingSaveAlert = true
            }
        }
        .padding()
    }
    
    private func addFilterItem() {
        filterItems.append(FilterItem(criteria: .quote, filterType: .single))
    }
    
    private func removeFilterItem(at index: Int) {
        filterItems.remove(at: index)
    }
    
    private func groupFilters(at index: Int) {
        guard index < filterItems.count - 1 else { return }
        let group = FilterItem(
            criteria: .quote,
            filterType: .group,
            items: Array(filterItems[index...index + 1]),
            openParen: true,
            closeParen: true
        )
        filterItems.removeSubrange(index...(index + 1))
        filterItems.insert(group, at: index)
    }
}
