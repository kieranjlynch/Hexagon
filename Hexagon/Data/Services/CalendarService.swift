//
//  CalendarService.swift
//  Hexagon
//
//  Created by Kieran Lynch on 03/10/2024.
//

import Foundation
import EventKit
import os

public protocol CalendarServiceProtocol {
    func requestCalendarAccess() async throws -> Bool
    func fetchEvents(from: Date, to: Date) async -> [EKEvent]
}

@MainActor
public class CalendarService: CalendarServiceProtocol {
    public static let shared = CalendarService()
    private let eventStore = EKEventStore()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.klynch.Hexagon", category: "CalendarService")

    public init() {}

    public func requestCalendarAccess() async throws -> Bool {
        try await eventStore.requestFullAccessToEvents()
    }
    
    public func fetchEvents(from startDate: Date, to endDate: Date) async -> [EKEvent] {
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        return eventStore.events(matching: predicate)
    }

    public func saveTaskToCalendar(title: String, startDate: Date, duration: TimeInterval) async throws {
        let authorizationStatus = try await eventStore.requestFullAccessToEvents()
        guard authorizationStatus else {
            logger.error("Calendar access denied")
            throw CalendarError.accessDenied
        }
        
        guard !title.isEmpty else {
            logger.error("Invalid title provided")
            throw CalendarError.invalidTitle
        }
        
        guard duration > 0 else {
            logger.error("Invalid duration provided: \(duration)")
            throw CalendarError.invalidDuration
        }

        do {
            let event = EKEvent(eventStore: eventStore)
            event.title = title
            event.startDate = startDate
            event.endDate = startDate.addingTimeInterval(duration * 60)
            event.calendar = eventStore.defaultCalendarForNewEvents
            event.availability = .busy
            
            if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
                event.calendar = defaultCalendar
            } else {
                throw CalendarError.noDefaultCalendar
            }
            
            try eventStore.save(event, span: .thisEvent)
        } catch {
            logger.error("Failed to save calendar event: \(error.localizedDescription)")
            throw CalendarError.saveFailed(error)
        }
    }
    
    public enum CalendarError: LocalizedError {
        case accessDenied
        case invalidTitle
        case invalidDuration
        case noDefaultCalendar
        case saveFailed(Error)
        
        public var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "Calendar access denied. Please enable in Settings."
            case .invalidTitle:
                return "Task title cannot be empty"
            case .invalidDuration:
                return "Task duration must be greater than 0"
            case .noDefaultCalendar:
                return "No default calendar available"
            case .saveFailed(let error):
                return "Failed to save event: \(error.localizedDescription)"
            }
        }
    }
}
