import SwiftUI
import EventKit

struct AgendaView: View {
    @Binding var selectedDate: Date
    @Binding var selectedDuration: Double
    @State private var events: [EKEvent] = []
    
    var body: some View {
        VStack(spacing: 0) {
            DateHeaderView(selectedDate: $selectedDate, onDateChanged: { date in
                selectedDate = date
                fetchEvents()
            })
            
            Divider()
            
            TimeSlotsView(events: events, selectedDate: selectedDate)
        }
        .onAppear {
            fetchEvents()
        }
    }
    
    func fetchEvents() {
        let eventStore = EKEventStore()
        
        eventStore.requestWriteOnlyAccessToEvents { (granted, error) in
            if granted {
                let startOfDay = Calendar.current.startOfDay(for: selectedDate)
                let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
                
                let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
                let events = eventStore.events(matching: predicate)
                
                DispatchQueue.main.async {
                    self.events = events
                }
            }
        }
    }
}
