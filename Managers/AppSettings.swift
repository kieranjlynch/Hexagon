//
//  AppSettings.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI

class AppSettings: ObservableObject {
    @Published var errorMessage: String? = nil
    @Published var isErrorPresented: Bool = false
    @AppStorage("appTintColorRed") var appTintColorRed: Double = 1.0
    @AppStorage("appTintColorGreen") var appTintColorGreen: Double = 0.5
    @AppStorage("appTintColorBlue") var appTintColorBlue: Double = 0.0
    
    var appTintColor: Color {
        Color(red: appTintColorRed, green: appTintColorGreen, blue: appTintColorBlue)
    }
}
