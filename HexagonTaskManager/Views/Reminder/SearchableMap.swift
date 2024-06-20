import SwiftUI
import MapKit

struct SearchableMap: View {
    @State private var position = MapCameraPosition.automatic
    @State private var searchResults = [SearchResult]()
    @State private var selectedLocation: SearchResult?
    @State private var isSheetPresented: Bool = true
    @State private var scene: MKLookAroundScene?
    @State private var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    let onSave: (String, Double, Double) -> Void
    
    var body: some View {
        Map(position: $position, selection: $selectedLocation) {
            ForEach(searchResults) { result in
                Marker(coordinate: result.location) {
                    Image(systemName: "mappin")
                }
                .tag(result)
            }
        }
        .overlay(alignment: .bottom) {
            if selectedLocation != nil {
                LookAroundPreview(scene: $scene, allowsNavigation: false, badgePosition: .bottomTrailing)
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .safeAreaPadding(.bottom, 40)
                    .padding(.horizontal, 20)
            }
        }
        .ignoresSafeArea()
        .onChange(of: selectedLocation) { oldValue, newValue in
            if let selectedLocation = newValue {
                Task {
                    scene = try? await fetchScene(for: selectedLocation.location)
                    let name = selectedLocation.id.uuidString
                    let latitude = selectedLocation.location.latitude
                    let longitude = selectedLocation.location.longitude
                    onSave(name, latitude, longitude)
                }
            }
            isSheetPresented = newValue == nil
        }
        .onChange(of: searchResults) {
            if let firstResult = searchResults.first, searchResults.count == 1 {
                selectedLocation = firstResult
            }
        }
        .sheet(isPresented: $isSheetPresented) {
            LocationSearchView(mapRegion: $mapRegion, searchResults: $searchResults)
        }
    }
    
    private func fetchScene(for coordinate: CLLocationCoordinate2D) async throws -> MKLookAroundScene? {
        let lookAroundScene = MKLookAroundSceneRequest(coordinate: coordinate)
        return try await lookAroundScene.scene
    }
}
