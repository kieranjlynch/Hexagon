//
//  Curve.swift
//  Hexagon
//
//  Created by Kieran Lynch on 09/10/2024.
//

import SwiftUI

struct Curve: Identifiable {
    var id = UUID()
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat
    
    init() {
        amplitude = CGFloat.random(in: 0.5...1.5)
        frequency = CGFloat.random(in: 0.6...0.9)
        phase = CGFloat.random(in: -1.0...1.0)
    }
}
