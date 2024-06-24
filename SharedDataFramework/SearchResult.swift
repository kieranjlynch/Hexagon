//
//  SearchResult.swift
//  SharedDataFramework
//
//  Created by Kieran Lynch on 21/06/2024.
//

import Foundation
import CoreLocation

public struct SearchResult: Identifiable, Hashable {
    public let id = UUID()
    public let location: CLLocationCoordinate2D

    public init(location: CLLocationCoordinate2D) {
        self.location = location
    }

    public static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
