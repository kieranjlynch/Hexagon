//
//  LocationViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 02/11/2024.
//

import Foundation
import CoreData
import MapKit
import Combine
import os


private let logger = Logger(subsystem: "com.hexagon", category: "LocationViewModel")

enum PermissionStatus: Equatable {
    case notDetermined
    case denied
    case restricted
    case authorized
}

struct LocationViewState: Equatable {
    var locations: [LocationModel] = []
    var searchResults: [MKMapItem] = []
    var selectedLocation: LocationModel?
    var region: MKCoordinateRegion
    var permissionStatus: PermissionStatus = .notDetermined
    
    init(initialRegion: MKCoordinateRegion) {
        self.region = initialRegion
    }
    
    static func == (lhs: LocationViewState, rhs: LocationViewState) -> Bool {
        lhs.locations == rhs.locations &&
        lhs.searchResults == rhs.searchResults &&
        lhs.selectedLocation == rhs.selectedLocation &&
        lhs.region.center.latitude == rhs.region.center.latitude &&
        lhs.region.center.longitude == rhs.region.center.longitude &&
        lhs.region.span.latitudeDelta == rhs.region.span.latitudeDelta &&
        lhs.region.span.longitudeDelta == rhs.region.span.longitudeDelta &&
        lhs.permissionStatus == rhs.permissionStatus
    }
}

@MainActor
final class LocationViewModel: ObservableObject {
    @Published private(set) var viewState: LocationViewState
    @Published var error: IdentifiableError?
    @Published var state: ViewState<LocationViewState> = .idle
    @Published var searchQuery: String = ""
    @Published private(set) var searchResults: [MKMapItem] = []
    
    private var cancellables: Set<AnyCancellable> = []
    
    private let locationService: LocationManaging
    private let searchService: any MapSearching
    private let permissionsHandler: LocationPermissionsHandling
    private let debounceInterval: TimeInterval
    private var searchTask: Task<Void, Never>?
    
    var locations: [LocationModel] { viewState.locations }
    
    init(
        locationService: LocationManaging,
        searchService: any MapSearching,
        permissionsHandler: LocationPermissionsHandling,
        initialRegion: MKCoordinateRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        ),
        debounceInterval: TimeInterval = 0.5
    ) {
        self.locationService = locationService
        self.searchService = searchService
        self.permissionsHandler = permissionsHandler
        self.debounceInterval = debounceInterval
        self.viewState = LocationViewState(initialRegion: initialRegion)
        
        setupSearchSubscription()
    }
    
    func viewDidLoad() {
        Task {
            await checkPermissionsAndLoadLocations()
        }
    }
}

// MARK: - DataLoadable
extension LocationViewModel: DataLoadable {
    typealias LoadedData = [LocationModel]
    
    nonisolated func loadContent() async throws -> [LocationModel] {
        try await locationService.fetchLocations()
    }
    
    nonisolated func handleLoadedContent(_ locations: [LocationModel]) {
        Task { @MainActor in
            self.viewState.locations = locations
            self.state = ViewState.loaded(self.viewState)
        }
    }
    
    nonisolated func handleLoadError(_ error: Error) {
        Task { @MainActor in
            logger.error("Failed to load locations: \(error.localizedDescription)")
            self.error = IdentifiableError(error: error)
            self.state = ViewState.error(error.localizedDescription)
        }
    }
}

// MARK: - Public Methods
extension LocationViewModel {
    func updateSearchQuery(_ query: String) {
        searchQuery = query
    }
    
    func refreshLocations() async {
        state = ViewState.loading
        do {
            let locations = try await loadContent()
            handleLoadedContent(locations)
        } catch {
            handleLoadError(error)
        }
    }
    
    func selectLocation(_ location: LocationModel?) {
        viewState.selectedLocation = location
    }
    
    func saveLocation(_ name: String, coordinate: CLLocationCoordinate2D) async {
        state = ViewState.loading
        
        do {
            try await locationService.saveLocation(name, coordinate: coordinate)
            await refreshLocations()
        } catch {
            state = ViewState.error(error.localizedDescription)
            logger.error("Failed to save location: \(error.localizedDescription)")
        }
    }
    
    func performSearch() async {
        guard !searchQuery.isEmpty else {
            searchResults = []
            state = ViewState.noResults
            return
        }
        
        state = ViewState.searching
        
        do {
            let results = try await searchService.searchLocations(
                query: searchQuery,
                in: viewState.region
            )
            self.searchResults = results
            state = results.isEmpty ? ViewState.noResults : ViewState.results(self.viewState)
        } catch {
            state = ViewState.error(error.localizedDescription)
            logger.error("Search failed: \(error.localizedDescription)")
        }
    }
    
    
    func updateRegion(_ newRegion: MKCoordinateRegion) {
        viewState.region = newRegion
    }
}

// MARK: - Private Methods
private extension LocationViewModel {
    func setupSearchSubscription() {
        $searchQuery
            .debounce(for: .seconds(debounceInterval), scheduler: DispatchQueue.main)
            .sink { [weak self] (newValue: String) in
                guard let self = self else { return }
                self.searchTask?.cancel()
                self.searchTask = Task {
                    await self.performSearch()
                }
            }
            .store(in: &cancellables)
    }
    
    func checkPermissionsAndLoadLocations() async {
        do {
            let isAuthorized = try await permissionsHandler.requestLocationPermissions()
            viewState.permissionStatus = isAuthorized ? .authorized : .denied
            
            if isAuthorized {
                await refreshLocations()
            }
        } catch {
            viewState.permissionStatus = .restricted
            state = ViewState.error(error.localizedDescription)
            logger.error("Permission check failed: \(error.localizedDescription)")
        }
    }
}
