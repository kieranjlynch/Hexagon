//
//  WaveShape.swift
//  Hexagon
//
//  Created by Kieran Lynch on 09/10/2024.
//

import SwiftUI

struct WaveShape: Shape {
    var wave: Wave
    var animatableData: Wave.AnimatableData {
        get { wave.animatableData }
        set { wave.animatableData = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let width = rect.width
        let height = rect.height / 2
        
        let progress = wave.time
        let power = wave.power
        
        path.move(to: CGPoint(x: 0, y: midY))
        
        for x in stride(from: 0, to: width + 1, by: 1) {
            var y: CGFloat = 0.0
            for curve in wave.curves {
                let normedX = x / width
                let scaling = -pow(normedX - 0.5, 2) + 0.25
                let sine = sin(2 * .pi * (curve.frequency * normedX + progress) + curve.phase)
                let amplitudeScaling = pow(power, 1.5)
                y += scaling * height * curve.amplitude * sine * amplitudeScaling
            }
            y = (y / CGFloat(wave.curves.count)) + midY
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}
