//
//  LocationViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI
import os
import MapKit
import HexagonData
import Combine

@MainActor
class LocationViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [IdentifiableMapItem] = []
    @Published var selectedLocation: IdentifiableMapItem?
    @Published var errorMessage: String?
    
    private let locationService: LocationService
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.hexagon", category: "LocationViewModel")
    private var cancellables = Set<AnyCancellable>()
    
    init(locationService: LocationService) {
        self.locationService = locationService
        setupCombineBindings()
    }
    
    // MARK: - Combine Bindings
    
    private func setupCombineBindings() {
        // Monitor searchText changes and trigger search automatically
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                guard !searchText.isEmpty else {
                    self?.searchResults = []
                    return
                }
                Task {
                    await self?.searchLocations()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Async/Await Functions
    
    func searchLocations() async {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        do {
            let results = try await locationService.search(with: searchText, coordinate: locationService.currentLocation)
            self.searchResults = results.map { IdentifiableMapItem(mapItem: MKMapItem(placemark: MKPlacemark(coordinate: $0.location))) }
        } catch {
            handleSearchError(error)
        }
    }
    
    func selectLocation(_ location: IdentifiableMapItem) {
        selectedLocation = location
        if let coordinate = location.mapItem.placemark.location?.coordinate {
            locationService.currentLocation = coordinate
        }
    }
    
    func saveLocation(name: String, onSave: @escaping (String, Double, Double) -> Result<Void, Error>) {
        guard let selectedLocation = selectedLocation,
              let coordinate = selectedLocation.mapItem.placemark.location?.coordinate else {
            errorMessage = "No location selected"
            return
        }
        
        let result = onSave(name, coordinate.latitude, coordinate.longitude)
        switch result {
        case .success: break
        case .failure(let error):
            logger.error("Failed to save location: \(error.localizedDescription)")
            errorMessage = "Failed to save location: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Error Handling
    
    private func handleSearchError(_ error: Error) {
        logger.error("Failed to search locations: \(error.localizedDescription)")
        if let error = error as NSError?, error.domain == kCLErrorDomain {
            errorMessage = "Location services error. Please check your settings."
        } else {
            errorMessage = "Failed to search locations. Please try again."
        }
        searchResults = []
    }
}
