//
//  ErrorHandlerService.swift
//  Hexagon
//
//  Created by Kieran Lynch on 03/12/2024.
//

import Foundation
import os
import SwiftUI

public protocol ErrorHandling: AnyObject {
    @MainActor func handle(_ error: Error)
    @MainActor func handle(_ error: Error, logger: Logger?)
}

@MainActor
public class ErrorHandlerService: ErrorHandling, ObservableObject {
    @Published private(set) var currentError: AppError?
    
    public static let shared = ErrorHandlerService()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "ErrorHandler")
    
    private init() {}
    
    public func handle(_ error: Error) {
        handle(error, logger: nil)
    }
    
    public func handle(_ error: Error, logger: Logger?) {
        let appError: AppError
        
        if let error = error as? AppError {
            appError = error
        } else {
            appError = BaseAppError(
                errorCode: -1,
                category: .system,
                description: error.localizedDescription,
                underlyingError: error
            )
        }
        
        // Log the error
        let errorLogger = logger ?? self.logger
        errorLogger.error("\(appError.errorDescription ?? "Unknown error")")
        
        if let underlying = appError.underlyingError {
            errorLogger.error("\(underlying.localizedDescription)")
        }
        
        currentError = appError
    }
}
