//
//  DateFieldsView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI

struct DateFieldsView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date?
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
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
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
                    selection: Binding(get: {
                        endDate ?? startDate
                    }, set: { newValue in
                        endDate = newValue
                    }),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
            }
        }
        .onAppear {
            DateFormatter.updateSharedDateFormatter()
        }
    }
}
