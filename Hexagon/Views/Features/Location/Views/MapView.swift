//
//  MapView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 02/11/2024.
//

import SwiftUI
import MapKit


struct MapView: View {
    @StateObject private var viewModel: LocationViewModel
    @StateObject private var searchService: MapSearchService
    @State private var newLocationName = ""
    @State private var showingNameInput = false
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedSearchResult: MKMapItem?
    @State private var showSearchResults = false
    @State private var isSearching = false
    @State private var showingSavedLocations = false
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var showingLookAround = false
    
    init(viewModel: LocationViewModel, searchService: MapSearchService) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _searchService = StateObject(wrappedValue: searchService)
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                mapView
                actionButtons
                
                if showSearchResults && isSearching {
                    searchResultsView
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding()
                        .transition(.move(edge: .top))
                }
            }
        }
        .sheet(isPresented: $showingNameInput) {
            nameInputSheet
        }
        .sheet(isPresented: $showingSavedLocations) {
            SavedLocationsView(locations: viewModel.locations) { location in
                withAnimation {
                    position = .region(MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            }
        }
        .lookAroundViewer(isPresented: $showingLookAround, scene: $lookAroundScene)
    }
    
    private var mapView: some View {
        Map(position: $position, selection: $selectedSearchResult) {
            ForEach(viewModel.locations) { location in
                Annotation(location.name, coordinate: location.coordinate) {
                    Image(systemName: "star.circle.fill")
                        .foregroundStyle(.red)
                        .background(.white)
                        .clipShape(.circle)
                }
            }
            
            if let selectedItem = selectedSearchResult,
               let location = selectedItem.placemark.location {
                Annotation(selectedItem.name ?? "Selected Location",
                           coordinate: location.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.blue)
                        .background(.white)
                        .clipShape(.circle)
                }
            }
            
            UserAnnotation()
        }
        .ignoresSafeArea(edges: .all)
        .mapControls {
            MapUserLocationButton()
        }
        .searchable(text: $viewModel.searchQuery,
                    isPresented: $isSearching,
                    prompt: "Search places")
        .onChange(of: viewModel.searchQuery) { _, newValue in
            handleSearchQueryChange(newValue)
        }
        .task(id: selectedSearchResult) {
            await handleSelectedSearchResult()
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    showingSavedLocations = true
                } label: {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("Saved")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Button {
                    showingNameInput = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add New")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selectedSearchResult != nil ? Color.blue : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(selectedSearchResult == nil)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
    
    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(viewModel.searchResults, id: \.self) { item in
                    Button {
                        selectSearchResult(item)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name ?? "Unknown Location")
                                .font(.headline)
                            if let subtitle = item.placemark.title {
                                Text(subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var nameInputSheet: some View {
        NavigationStack {
            Form {
                Section {
                    if let item = selectedSearchResult {
                        Text("Location: \(item.name ?? "Unknown")")
                            .foregroundStyle(.secondary)
                    }
                    
                    TextField("Name (e.g., Home, Work, Gym)", text: $newLocationName)
                        .autocorrectionDisabled()
                }
                
                Section {
                    Text("Give this location a name that's meaningful to you")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .navigationTitle("Name Location")
            .navigationBarItems(
                leading: Button("Cancel") {
                    showingNameInput = false
                    newLocationName = ""
                },
                trailing: Button("Save") {
                    Task {
                        await saveLocation()
                    }
                }
                    .disabled(newLocationName.isEmpty)
            )
        }
        .presentationDetents([.height(250)])
    }
    
    private func handleSearchQueryChange(_ newValue: String) {
        showSearchResults = !newValue.isEmpty
        Task {
            await viewModel.performSearch()
        }
    }
    
    private func handleSelectedSearchResult() async {
        if let location = selectedSearchResult?.placemark.location {
            lookAroundScene = try? await MKLookAroundSceneRequest(coordinate: location.coordinate).scene
        } else {
            lookAroundScene = nil
        }
    }
    
    private func selectSearchResult(_ item: MKMapItem) {
        selectedSearchResult = item
        showSearchResults = false
        viewModel.searchQuery = ""
        isSearching = false
        
        if let coordinate = item.placemark.location?.coordinate {
            withAnimation {
                position = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
    }
    
    private func saveLocation() async {
        if let item = selectedSearchResult,
           let location = item.placemark.location {
            await viewModel.saveLocation(newLocationName, coordinate: location.coordinate)
            showingNameInput = false
            selectedSearchResult = nil
            newLocationName = ""
        }
    }
}
