import SwiftUI

struct NotificationSheetView: View {
    @State private var notificationTurnedOn = false
    @State private var selectedReminderTime = 0
    @State private var selectedLocation: Location?
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Location.name, ascending: true)])
    private var locations: FetchedResults<Location>
    @State private var isShowingMap = false
    
    let reminderTimes = [
        "15 minutes before",
        "30 minutes before",
        "1 hour before",
        "6 hours before",
        "12 hours before",
        "24 hours before"
    ]
    
    var body: some View {
        Form {
            Toggle("Notify me", isOn: $notificationTurnedOn)
                .toggleStyle(SwitchToggleStyle(tint: .orange))
            
            if notificationTurnedOn {
                Picker("Reminder Time", selection: $selectedReminderTime) {
                    ForEach(0..<reminderTimes.count, id: \.self) { index in
                        Text(reminderTimes[index]).tag(index)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(.offWhite)
                .tint(.orange)
                
                HStack {
                    Picker("Remind me at a Location", selection: $selectedLocation) {
                        Text("None").tag(nil as Location?)
                        ForEach(locations) { location in
                            Text(location.name ?? "").tag(location as Location?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .tint(.orange)
                    
                    Button(action: {
                        isShowingMap = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.offWhite)
                    }
                    .sheet(isPresented: $isShowingMap) {
                        SearchableMap(onSave: { name, latitude, longitude in
                            do {
                                try CoreDataProvider.shared.saveLocation(name: name, latitude: latitude, longitude: longitude)
                            } catch {
                                print("Failed to save new location: \(error)")
                            }
                        })
                    }
                }
            }
        }
        .listRowBackground(Color.customBackgroundColor)
        .environment(\.colorScheme, .dark)
    }
}
