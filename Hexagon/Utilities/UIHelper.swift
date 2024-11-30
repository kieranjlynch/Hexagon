//
//  UIHelper.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI

enum UIHelper {
    static func inboxTipOffset(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return -120
        case .medium:
            return -130
        case .large:
            return -140
        case .xLarge:
            return -150
        case .xxLarge:
            return -160
        case .xxxLarge:
            return -170
        case .accessibility1:
            return -180
        case .accessibility2:
            return -190
        case .accessibility3:
            return -200
        case .accessibility4:
            return -210
        case .accessibility5:
            return -220
        @unknown default:
            return -130
        }
    }
    
    static func inboxTipXOffset(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return -20
        case .medium:
            return -25
        case .large:
            return -30
        case .xLarge:
            return -35
        case .xxLarge:
            return -40
        case .xxxLarge:
            return -45
        case .accessibility1:
            return -50
        case .accessibility2:
            return -55
        case .accessibility3:
            return -60
        case .accessibility4:
            return -65
        case .accessibility5:
            return -70
        @unknown default:
            return -25
        }
    }
}
