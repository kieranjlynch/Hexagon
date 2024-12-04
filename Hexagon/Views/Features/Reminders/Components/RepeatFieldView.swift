//
//  RepeatFieldView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 08/11/2024.
//

import SwiftUI

struct RepeatFieldView: View {
    @Binding var repeatOption: RepeatOption
    @Binding var customRepeatInterval: Int
    var colorScheme: ColorScheme
    
    var body: some View {
        Menu {
            ForEach(RepeatOption.allCases, id: \.self) { option in
                Button {
                    repeatOption = option
                } label: {
                    if repeatOption == option {
                        Label(option.rawValue, systemImage: "checkmark")
                    } else {
                        Text(option.rawValue)
                    }
                }
            }
        } label: {
            Text(repeatOption.rawValue)
                .foregroundColor(.blue)
        }
    }
}
