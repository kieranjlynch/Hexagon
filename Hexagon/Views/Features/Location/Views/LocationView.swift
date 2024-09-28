import SwiftUI
import MapKit
import CoreLocation
import CoreData
import os
import HexagonData

struct IdentifiableMapItem: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem
}

struct LocationView: View {
    @StateObject private var viewModel: LocationViewModel
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var locationService: LocationService
    @Binding var isPresented: Bool
    @State private var showingSaveLocationAlert = false
    @State private var newLocationName = ""
    
    var onSave: (String, Double, Double) -> Result<Void, Error>
    
    init(locationService: LocationService, isPresented: Binding<Bool>, onSave: @escaping (String, Double, Double) -> Result<Void, Error>) {
        _viewModel = StateObject(wrappedValue: LocationViewModel(locationService: locationService))
        _isPresented = isPresented
        self.onSave = onSave
    }
    
    var body: some View {
        VStack {
            ZStack {
                mapView(currentLocation: locationService.currentLocation, selectedLocation: $viewModel.selectedLocation)
                closeButton(action: { isPresented = false })
            }
            
            TextField(Constants.Strings.searchPlaceholder, text: $viewModel.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: viewModel.searchText) { oldValue, newValue in
                    Task {
                        await viewModel.searchLocations()
                    }
                }
            
            List {
                Section(header: Text(Constants.Strings.searchResultsHeader).preferredColorScheme(colorScheme)) {
                    ForEach(viewModel.searchResults) { result in
                        Text(result.mapItem.name ?? Constants.Strings.unknownLocation)
                            .onTapGesture {
                                viewModel.selectLocation(result)
                            }
                    }
                }
            }
            
            if viewModel.selectedLocation != nil {
                Button(Constants.Strings.saveLocationButton) {
                    showingSaveLocationAlert = true
                }
                .padding()
            }
        }
        .alert(Constants.Strings.saveLocationAlertTitle, isPresented: $showingSaveLocationAlert) {
            TextField("Location Name", text: $newLocationName)
            Button(Constants.Strings.saveButton) {
                viewModel.saveLocation(name: newLocationName, onSave: onSave)
                isPresented = false
            }
            Button(Constants.Strings.cancelButton, role: .cancel) {}
        } message: {
            Text(Constants.Strings.saveLocationAlertMessage)
        }
        .errorAlert(errorMessage: $viewModel.errorMessage)
    }
}
