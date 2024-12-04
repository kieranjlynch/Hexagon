//
//  DomainErrors.swift
//  Hexagon
//
//  Created by Kieran Lynch on 03/12/2024.
//

import Foundation

public enum DatabaseError: AppError {
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case invalidEntity(String)
    case contextMissing
    
    public var errorCode: Int {
        switch self {
        case .fetchFailed: return 1001
        case .saveFailed: return 1002
        case .deleteFailed: return 1003
        case .invalidEntity: return 1004
        case .contextMissing: return 1005
        }
    }
    
    public var category: ErrorCategory { .database }
    
    public var errorDescription: String? {
        switch self {
        case .fetchFailed(let entity): return "Failed to fetch \(entity)"
        case .saveFailed(let entity): return "Failed to save \(entity)"
        case .deleteFailed(let entity): return "Failed to delete \(entity)"
        case .invalidEntity(let entity): return "Invalid entity: \(entity)"
        case .contextMissing: return "NSManagedObjectContext is missing"
        }
    }
    
    public var underlyingError: Error? { nil }
}

public enum ValidationError: AppError {
    case invalidInput(String)
    case missingRequired(String)
    case exceedsLimit(String)
    
    public var errorCode: Int {
        switch self {
        case .invalidInput: return 2001
        case .missingRequired: return 2002
        case .exceedsLimit: return 2003
        }
    }
    
    public var category: ErrorCategory { .validation }
    
    public var errorDescription: String? {
        switch self {
        case .invalidInput(let field): return "Invalid input for \(field)"
        case .missingRequired(let field): return "\(field) is required"
        case .exceedsLimit(let message): return "\(message)"
        }
    }
    
    public var underlyingError: Error? { nil }
}
