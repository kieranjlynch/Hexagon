// PerformanceMonitor.swift
// Hexagon
//
// Created by Kieran Lynch on 09/11/2024.
//

import Foundation
import os
import QuartzCore

public protocol PerformanceMonitoring: Actor {
    var operations: [String: CFTimeInterval] { get set }
    func startOperation(_ name: String) async
    func endOperation(_ name: String) async
}

public actor PerformanceMonitor: PerformanceMonitoring {
    public let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "PerformanceMonitor")
    public var operations: [String: CFTimeInterval] = [:]
    public let queue = DispatchQueue(label: "com.hexagon.performanceMonitor", qos: .utility)

    public init() {}

    public func startOperation(_ name: String) async {
        operations[name] = CACurrentMediaTime()
    }

    public func endOperation(_ name: String) async {
        guard let startTime = operations[name] else { return }
        let duration = CACurrentMediaTime() - startTime
        operations.removeValue(forKey: name)
        
        if duration > 0.1 {
            logger.warning("Operation '\(name)' took \(duration) seconds")
        }
    }
}
