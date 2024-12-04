//
//  AppError.swift
//  Hexagon
//
//  Created by Kieran Lynch on 03/12/2024.
//

import Foundation

public protocol AppError: LocalizedError {
    var errorCode: Int { get }
    var category: ErrorCategory { get }
    var underlyingError: Error? { get }
}

public enum ErrorCategory {
    case system
    case network
    case data
    case validation
    case database
    case ui
}


public struct BaseAppError: AppError {
    public let errorCode: Int
    public let category: ErrorCategory
    public let errorDescription: String?
    public let underlyingError: Error?
    
    public init(
        errorCode: Int,
        category: ErrorCategory,
        description: String,
        underlyingError: Error? = nil
    ) {
        self.errorCode = errorCode
        self.category = category
        self.errorDescription = description
        self.underlyingError = underlyingError
    }
}
