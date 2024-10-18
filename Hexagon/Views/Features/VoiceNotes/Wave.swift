//
//  Wave.swift
//  Hexagon
//
//  Created by Kieran Lynch on 09/10/2024.
//

import SwiftUI

struct Wave: Identifiable, Animatable {
    var id = UUID()
    var power: CGFloat
    var time: CGFloat
    var curves: [Curve]
    
    init(power: CGFloat, time: CGFloat = 0) {
        self.power = power
        self.time = time
        self.curves = (0..<4).map { _ in Curve() }
    }
    
    typealias AnimatableData = AnimatablePair<CGFloat, CGFloat>
    
    var animatableData: AnimatableData {
        get { AnimatablePair(power, time) }
        set {
            power = newValue.first
            time = newValue.second
        }
    }
}
