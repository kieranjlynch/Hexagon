//
//  CalendarService.swift
//  Hexagon
//
//  Created by Kieran Lynch on 03/10/2024.
//

import Foundation
import EventKit

@MainActor
public class CalendarService {
    public static let shared = CalendarService()
    
    private let eventStore = EKEventStore()
    
    public func saveTaskToCalendar(title: String, startDate: Date, duration: TimeInterval) async throws {
        let authorizationStatus = try await eventStore.requestFullAccessToEvents()
        guard authorizationStatus else {
            throw NSError(domain: "com.yourdomain.Hexagon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Calendar access denied"])
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(duration * 60)
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        try eventStore.save(event, span: .thisEvent)
    }
}
