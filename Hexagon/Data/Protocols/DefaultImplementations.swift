//
// DefaultImplementations.swift
// Hexagon
//
// Created by Kieran Lynch on [Current Date]
//

import Foundation
import CoreData

// MARK: - Default Implementation for PerformanceMonitoring
public actor DefaultPerformanceMonitor: PerformanceMonitoring {
    public var operations: [String: CFTimeInterval] = [:]
    
    public init() {}
    
    public func startOperation(_ name: String) async {}
    public func endOperation(_ name: String) async {}
}
