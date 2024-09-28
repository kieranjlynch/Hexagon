//
//  EventView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import EventKit

struct EventView: View {
    @Environment(\.colorScheme) var colorScheme
    let event: EKEvent
    
    var body: some View {
        Text(event.title)
            .padding(10)
            .cardStyle()
            .foregroundColor(colorScheme == .dark ? .white : .black)
    }
}
