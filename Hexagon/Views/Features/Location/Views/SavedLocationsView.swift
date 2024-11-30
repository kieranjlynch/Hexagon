//
//  SavedLocationsView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 02/11/2024.
//

import SwiftUI

import MapKit

struct SavedLocationsView: View {
    @Environment(\.dismiss) private var dismiss
    let locations: [LocationModel]
    let onLocationSelected: (LocationModel) -> Void
    
    var body: some View {
        NavigationStack {
            List(locations) { location in
                Button {
                    onLocationSelected(location)
                    dismiss()
                } label: {
                    HStack {
                        Text(location.name)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Saved Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
