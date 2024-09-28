//
//  CustomButton.swift
//  Hexagon
//
//  Created by Kieran Lynch on 12/09/2024.
//

import SwiftUI

enum CustomButtonStyle {
    case primary
    case secondary
}

struct CustomButton: View {
    let title: String
    let action: () -> Void
    let style: CustomButtonStyle
    
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appSettings: AppSettings
    
    var body: some View {
        styledButton(title: title, style: style, appTintColor: appSettings.appTintColor, action: action)
    }
}
