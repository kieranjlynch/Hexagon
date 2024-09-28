//
//  DateHeaderView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI

struct DateHeaderView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedDate: Date
    let onDateChanged: (Date) -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                dateNavButton(systemName: "chevron.left") {
                    let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                    onDateChanged(previousDate)
                }
                
                Spacer()
                
                Text(DateFormatter.sharedDateFormatter.string(from: selectedDate))
                    .font(.headline)
                    .adaptiveColors()
                
                Spacer()
                
                dateNavButton(systemName: "chevron.right") {
                    let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                    onDateChanged(nextDate)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}
