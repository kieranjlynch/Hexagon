import SwiftUI

struct PrioritySheetView: View {
    @Binding var priority: Int
    
    var body: some View {
        Form {
            Picker("Priority", selection: $priority) {
                Text("Low")
                    .foregroundColor(.offWhite)
                    .tag(0)
                Text("Medium")
                    .foregroundColor(.offWhite)
                    .tag(1)
                Text("High")
                    .foregroundColor(.offWhite)
                    .tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .tint(.orange)
        }
        .listRowBackground(Color.customBackgroundColor)
        .environment(\.colorScheme, .dark)
    }
}
