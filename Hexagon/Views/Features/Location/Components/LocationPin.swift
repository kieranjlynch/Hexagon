//
//  Untitled.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI
import CoreLocation

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
