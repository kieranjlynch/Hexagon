//
//  DateFieldsView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI

struct DateFieldsView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    var colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label {
                    Text("Start")
                } icon: {
                    Image(systemName: "calendar")
                }
                .foregroundColor(colorScheme == .dark ? .white : .black)
                Spacer()
                DatePicker(
                    "",
                    selection: $startDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "en_US_POSIX"))
                .environment(\.calendar, Calendar(identifier: .gregorian))
                .environment(\.timeZone, TimeZone(secondsFromGMT: 0)!)
            }
            .padding(.bottom)

            HStack {
                Label {
                    Text("Due")
                } icon: {
                    Image(systemName: "calendar")
                }
                .foregroundColor(colorScheme == .dark ? .white : .black)
                Spacer()
                DatePicker(
                    "",
                    selection: $endDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "en_US_POSIX"))
                .environment(\.calendar, Calendar(identifier: .gregorian))
                .environment(\.timeZone, TimeZone(secondsFromGMT: 0)!)
            }            
        }
        .onAppear {
            DateFormatter.updateSharedDateFormatter()
        }
    }
}
