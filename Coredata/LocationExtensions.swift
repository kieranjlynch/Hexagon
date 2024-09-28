//
//  LocationExtensions.swift
//  Hexagon
//
//  Created by Kieran Lynch on 17/09/2024.
//

import CoreLocation
import HexagonData

extension Location {
    func toCoordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}
