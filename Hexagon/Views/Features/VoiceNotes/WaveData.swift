//
//  WaveData.swift
//  Hexagon
//
//  Created by Kieran Lynch on 09/10/2024.
//

import SwiftUI

final class WaveData: ObservableObject {
    @Published var waves: [Wave]
    let colors = [
        Color(red: 0.67, green: 0.22, blue: 0.30),
        Color(red: 0.18, green: 0.86, blue: 0.61),
        Color(red: 0.10, green: 0.48, blue: 1.0)
    ]
    
    init() {
        self.waves = colors.map { _ in Wave(power: 0) }
    }
    
    func update(power: CGFloat) {
        for index in waves.indices {
            waves[index].power = power
        }
    }
    
    func update(time: CGFloat) {
        for index in waves.indices {
            waves[index].time = time
        }
    }
}
