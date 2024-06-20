import SwiftUI

struct DateHeaderView: View {
    @Binding var selectedDate: Date
    let onDateChanged: (Date) -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: {
                    let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                    onDateChanged(previousDate)
                }) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(selectedDate, style: .date)
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                    onDateChanged(nextDate)
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}
