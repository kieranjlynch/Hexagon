//
//  TitleFieldView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI

struct TitleFieldView: View {
    @Binding var title: String
    var taskType: String
    var colorScheme: ColorScheme
    
    var body: some View {
        TextField("\(taskType.dropLast()) Title", text: $title)
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .textFieldStyle(.roundedBorder)
            .cornerRadius(Constants.UI.cornerRadius)
    }
}
