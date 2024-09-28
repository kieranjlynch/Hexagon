//
//  TaskScheduleView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import EventKit

struct TaskScheduleView: View {
    @AppStorage("preferredTaskType") private var preferredTaskType: String = "Tasks"
    @Environment(\.colorScheme) var colorScheme
    let task: String
    @State private var selectedDate = Date()
    @State private var selectedDuration = 60.0
    
    let durationOptions = [30, 60, 90, 120]
    
    var body: some View {
        NavigationView {
            VStack {
                AgendaView(selectedDate: $selectedDate, selectedDuration: $selectedDuration)
                
                Picker("Duration", selection: $selectedDuration) {
                    ForEach(durationOptions, id: \.self) { duration in
                        Text("\(duration) minutes").tag(Double(duration))
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                Button("Save to Calendar") {
                    saveTaskToCalendar()
                }
                .padding()
            }
            .navigationBarTitle("Schedule \(preferredTaskType.dropLast()): \(task)")
        }
        .onAppear {
            DateFormatter.updateSharedDateFormatter()
        }
    }

    func saveTaskToCalendar() {
        let eventStore = EKEventStore()
        
        eventStore.requestWriteOnlyAccessToEvents { (granted, error) in
            if !granted {
                return
            }
            
            let event = EKEvent(eventStore: eventStore)
            event.title = task
            event.startDate = selectedDate
            event.endDate = selectedDate.addingTimeInterval(selectedDuration * 60)
            event.calendar = eventStore.defaultCalendarForNewEvents
            
            let predicate = eventStore.predicateForEvents(withStart: event.startDate, end: event.endDate, calendars: [event.calendar])
            let conflictingEvents = eventStore.events(matching: predicate)
            
            if !conflictingEvents.isEmpty {
                return
            }
            
            do {
                try eventStore.save(event, span: .thisEvent)
                DispatchQueue.main.async {
                }
            } catch {
            }
        }
    }
}
