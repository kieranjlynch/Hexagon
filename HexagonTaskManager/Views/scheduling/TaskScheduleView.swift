import SwiftUI
import EventKit

struct TaskScheduleView: View {
    let task: String
    @State private var selectedDate = Date()
    @State private var selectedDuration = 60.0
    
    let durationOptions = [30, 60, 90, 120]
    
    var body: some View {
        NavigationView {
            VStack {
                AgendaView(selectedDate: $selectedDate, selectedDuration: $selectedDuration)
            }
            .navigationBarTitle("Schedule Task: \(task)")
        }
    }
    
    func saveTaskToCalendar() {
        let eventStore = EKEventStore()
        
        eventStore.requestWriteOnlyAccessToEvents { (granted, error) in
            if let error = error {
                print("Error requesting access to calendar: \(error.localizedDescription)")
                return
            }
            
            guard granted else {
                print("Access to calendar denied")
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
                print("There are conflicting events in the calendar")
                return
            }
            
            do {
                try eventStore.save(event, span: .thisEvent)
                DispatchQueue.main.async {
                    print("Task saved to calendar successfully")
                }
            } catch {
                print("Error saving task to calendar: \(error.localizedDescription)")
            }
        }
    }
}
