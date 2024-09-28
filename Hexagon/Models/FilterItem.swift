//
//  FilterItem.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import Foundation

public struct FilterItem: Identifiable, Codable {
    public var id: UUID
    public var criteria: FilterCriteria
    public var value: String?
    public var date: Date?
    public var isOn: Bool?
    public var filterType: FilterType
    public var items: [FilterItem]?
    public var openParen: Bool
    public var closeParen: Bool
    
    public init(id: UUID = UUID(), criteria: FilterCriteria, value: String? = nil, date: Date? = nil, isOn: Bool? = nil, filterType: FilterType = .single, items: [FilterItem]? = nil, openParen: Bool = false, closeParen: Bool = false) {
        self.id = id
        self.criteria = criteria
        self.value = value
        self.date = date
        self.isOn = isOn
        self.filterType = filterType
        self.items = items
        self.openParen = openParen
        self.closeParen = closeParen
    }
}

public enum FilterCriteria: String, Codable, CaseIterable {
    case quote = "Quote"
    case wildcard = "Wildcard"
    case tag = "Tag"
    case before = "Before"
    case after = "After"
    case priority = "Priority"
    case link = "Link"
    case notifications = "Notifications"
    case location = "Location"
    case notes = "Notes"
    case photos = "Photos"
}

