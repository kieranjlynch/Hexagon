//
//  TimeSlotsView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import EventKit

struct TimeSlotsView: View {
    @Environment(\.colorScheme) var colorScheme
    let events: [EKEvent]
    let selectedDate: Date
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(0..<24) { hour in
                    HStack(alignment: .top) {
                        Text(String(format: "%02d:00", hour))
                            .frame(width: 50, alignment: .trailing)
                            .padding(.trailing, 10)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        VStack(alignment: .leading) {
                            ForEach(eventsForHour(hour), id: \.eventIdentifier) { event in
                                EventView(event: event)
                            }
                        }
                        .padding(.vertical, 20)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Divider()
                }
            }
        }
    }
    
    private func eventsForHour(_ hour: Int) -> [EKEvent] {
        return events.filter { event in
            let eventHour = Calendar.current.component(.hour, from: event.startDate)
            return eventHour == hour
        }
    }
}
