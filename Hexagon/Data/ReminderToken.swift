//
//  ReminderToken.swift
//  HexagonData
//
//  Created by Kieran Lynch on 23/10/2024.
//

import Foundation

public enum ReminderToken: Codable, Identifiable, Hashable {
    case priority(Int16)
    case tag(UUID, String)
    
    public var id: String {
        switch self {
        case .priority(let value): return "priority_\(value)"
        case .tag(let id, _): return "tag_\(id)"
        }
    }
    
    public var displayName: String {
        switch self {
        case .priority(let value): return "Priority \(value)"
        case .tag(_, let name): return name
        }
    }
    
    public var icon: String {
        switch self {
        case .priority: return "flag"
        case .tag: return "tag"
        }
    }
}
