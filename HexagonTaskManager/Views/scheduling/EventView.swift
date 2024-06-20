import SwiftUI
import EventKit

struct EventView: View {
    let event: EKEvent
    
    var body: some View {
        Text(event.title)
            .padding(10)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(5)
    }
}
