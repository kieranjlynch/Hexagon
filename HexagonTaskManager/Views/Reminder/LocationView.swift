import SwiftUI
import MapKit
import CoreLocation
import CoreData
import SharedDataFramework

struct IdentifiableMapItem: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem
}

struct LocationPin: View {
    var coordinate: CLLocationCoordinate2D
    
    var body: some View {
        Image(systemName: "mappin.circle.fill")
            .foregroundColor(.red)
            .font(.title)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
    }
}

struct LocationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var searchResults: [IdentifiableMapItem] = []
    @State private var selectedLocation: IdentifiableMapItem?
    @State private var showingSaveLocationAlert = false
    @State private var newLocationName = ""
    @Binding var isPresented: Bool
    @State private var hasRequestedPermission = false

    var onSave: (String, Double, Double) -> Result<Void, Error>

    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack {
                    if let currentLocation = locationManager.currentLocation {
                        Map(coordinateRegion: .constant(MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))), showsUserLocation: true)
                            .frame(height: geometry.size.height / 2)
                        
                        if let selectedLocation = selectedLocation {
                            LocationPin(coordinate: selectedLocation.mapItem.placemark.coordinate)
                                .position(
                                    x: geometry.size.width / 2,
                                    y: geometry.size.height / 4
                                )
                        }
                    } else {
                        Text("Fetching location...")
                            .frame(height: geometry.size.height / 2)
                    }
                    
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                isPresented = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.black)
                                    .padding()
                            }
                        }
                        Spacer()
                    }
                }
                .onAppear {
                    if !hasRequestedPermission {
                        requestLocationPermission()
                    }
                }

                TextField("Search for a location", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: searchText) { newValue in
                        searchLocations(with: newValue)
                    }

                List {
                    Section(header: Text("Search Results")) {
                        ForEach(searchResults) { result in
                            Text(result.mapItem.name ?? "Unknown location")
                                .onTapGesture {
                                    selectLocation(result)
                                }
                        }
                    }
                }

                if selectedLocation != nil {
                    Button("Save Location") {
                        showingSaveLocationAlert = true
                    }
                    .padding()
                }
            }
            .alert("Save Location", isPresented: $showingSaveLocationAlert) {
                TextField("Location Name", text: $newLocationName)
                Button("Save") {
                    saveLocation()
                    isPresented = false
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter a name for this location")
            }
        }
    }

    private func searchLocations(with query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let currentLocation = locationManager.currentLocation {
            request.region = MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        }

        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                searchResults = []
                return
            }
            searchResults = response.mapItems.map { IdentifiableMapItem(mapItem: $0) }
        }
    }

    private func selectLocation(_ result: IdentifiableMapItem) {
        selectedLocation = result
        if let coordinate = result.mapItem.placemark.location?.coordinate {
            locationManager.currentLocation = coordinate
        }
    }

    private func saveLocation() {
        guard let selectedLocation = selectedLocation,
              let coordinate = selectedLocation.mapItem.placemark.location?.coordinate else { return }
        let result = onSave(newLocationName, coordinate.latitude, coordinate.longitude)
        switch result {
        case .success:
            newLocationName = ""
            self.selectedLocation = nil
        case .failure(let error):
            print("Failed to save location: \(error)")
        }
    }
    
    private func requestLocationPermission() {
        PermissionManager.shared.requestLocationPermission { granted in
            hasRequestedPermission = true
            if granted {
                locationManager.startUpdatingLocation()
            }
        }
    }
}
