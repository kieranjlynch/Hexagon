//
//  MapSearchService.swift
//  Hexagon
//
//  Created by Kieran Lynch on 02/11/2024.
//

import Foundation
import MapKit
import Combine

public protocol MapSearching {
    var searchResults: [MKMapItem] { get async }
    func searchLocations(query: String, in region: MKCoordinateRegion) async throws -> [MKMapItem]
}

@MainActor
public class MapSearchService: ObservableObject {
    public static let shared = MapSearchService()
    @Published private(set) var _searchResults: [MKMapItem] = []
    
    private init() {}
}

extension MapSearchService: MapSearching {
    nonisolated public var searchResults: [MKMapItem] {
        get async {
            await _searchResults
        }
    }
    
    public func searchLocations(query: String, in region: MKCoordinateRegion) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        request.region = region
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        await MainActor.run {
            self._searchResults = response.mapItems
        }
        
        return response.mapItems
    }
}
