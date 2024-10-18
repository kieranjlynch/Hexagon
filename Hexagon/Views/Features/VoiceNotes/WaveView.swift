//
//  WaveView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 09/10/2024.
//

import SwiftUI

struct WaveView: View {
    @Binding var power: CGFloat
    @ObservedObject private var data = WaveData()
    @State private var time: CGFloat = 0.0
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            ForEach(Array(data.waves.enumerated()), id: \.element.id) { i, wave in
                WaveShape(wave: wave)
                    .fill(data.colors[i])
                    .opacity(0.6)
            }
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
                time += 0.02
                data.update(time: time)
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .onChange(of: power) {
            data.update(power: power)
        }
        .drawingGroup()
    }
}
