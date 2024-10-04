//
//  FilterItemView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import Foundation
import HexagonData

struct FilterItemView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var item: FilterItem
    let onRemove: () -> Void
    let onGroup: () -> Void
    @State private var tags: [Tag] = []
    @EnvironmentObject private var reminderService: ReminderService
    @EnvironmentObject private var tagService: TagService

    var body: some View {
        HStack(spacing: 8) {
            if item.openParen {
                Text("(")
                    .font(.title2)
                    .adaptiveColors()
            }
            
            criteriaPicker
            
            criteriaView
            
            Spacer()
            
            actionButton(systemName: "text.badge.plus", action: onGroup, color: .blue)
            actionButton(systemName: "minus.circle.fill", action: onRemove, color: .red)
            
            if item.closeParen {
                Text(")")
                    .font(.title2)
                    .adaptiveColors()
            }
        }
        .padding(.vertical, 4)
        .adaptiveBackground()
        .task { await fetchTags() }
    }
    
    private var criteriaPicker: some View {
        Picker("", selection: $item.criteria) {
            ForEach(FilterCriteria.allCases, id: \.self) { criteria in
                Text(criteria.rawValue).tag(criteria)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .frame(width: 140)
    }
    
    private func actionButton(systemName: String, action: @escaping () -> Void, color: Color) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .foregroundColor(color)
        }
    }

    @ViewBuilder
    private var criteriaView: some View {
        switch item.criteria {
        case .quote, .wildcard:
            TextField("Value", text: Binding(get: { item.value ?? "" }, set: { item.value = $0 }))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: .infinity)
            
        case .tag:
            Picker("Select Tag", selection: Binding(get: { item.value ?? "" }, set: { item.value = $0 })) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag.name ?? "").tag(tag.name ?? "")
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity)
            
        case .before, .after:
            DatePicker(
                "",
                selection: Binding(
                    get: { item.date ?? Date() },
                    set: { item.date = $0 }
                ),
                displayedComponents: .date
            )
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .environment(\.locale, Locale(identifier: "en_US_POSIX"))
            .environment(\.calendar, Calendar(identifier: .gregorian))
            .environment(\.timeZone, TimeZone(secondsFromGMT: 0)!)
            
        case .priority:
            Picker("Priority", selection: Binding(get: { item.value ?? "1" }, set: { item.value = $0 })) {
                Text("Low").tag("1")
                Text("Medium").tag("2")
                Text("High").tag("3")
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(maxWidth: .infinity)
            
        case .link, .notifications, .location, .notes, .photos:
            Toggle("", isOn: Binding(get: { item.isOn ?? false }, set: { item.isOn = $0 }))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func fetchTags() async {
        do {
            tags = try await tagService.fetchTags()
        } catch {
            print("Failed to fetch tags: \(error)")
        }
    }
}
