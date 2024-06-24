// NotificationSheetView.swift

import SwiftUI
import SharedDataFramework

struct NotificationSheetView: View {
    @State private var selectedReminderTime: String?
    @State private var selectedLocation: Location?
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Location.name, ascending: true)])
    private var locations: FetchedResults<Location>
    @State private var isShowingMap = false
    @Environment(\.managedObjectContext) private var viewContext
    
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
            Section(header: Text("Reminder Time").foregroundColor(.offWhite)) {
                ForEach(reminderTimes, id: \.self) { time in
                    Button(action: {
                        selectedReminderTime = time
                    }) {
                        HStack {
                            Text(time)
                                .foregroundColor(.offWhite)
                            Spacer()
                            if selectedReminderTime == time {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Locations").foregroundColor(.offWhite)) {
                Button(action: {
                    isShowingMap = true
                }) {
                    Text("Add New Location")
                        .foregroundColor(.orange)
                }
                
                ForEach(locations) { location in
                    Button(action: {
                        selectedLocation = location
                    }) {
                        HStack {
                            Text(location.name ?? "")
                                .foregroundColor(.offWhite)
                            Spacer()
                            if selectedLocation == location {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
        }
        .listRowBackground(Color.customBackgroundColor)
        .environment(\.colorScheme, .dark)
        .sheet(isPresented: $isShowingMap) {
            LocationView(isPresented: $isShowingMap) { name, latitude, longitude in
                saveLocation(name: name, latitude: latitude, longitude: longitude)
            }
        }
    }
    
    private func saveLocation(name: String, latitude: Double, longitude: Double) -> Result<Void, Error> {
        let newLocation = Location(context: viewContext)
        newLocation.name = name
        newLocation.latitude = latitude
        newLocation.longitude = longitude
        
        do {
            try viewContext.save()
            selectedLocation = newLocation
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
