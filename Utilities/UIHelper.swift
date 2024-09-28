//
//  UIHelper.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI

struct UIHelper {
    static func inboxTipOffset(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium, .large, .xLarge:
            return -0
        case .xxLarge:
            return -0
        case .xxxLarge:
            return -0
        case .accessibility1:
            return -0
        case .accessibility2:
            return -0
        case .accessibility3:
            return -0
        case .accessibility4:
            return -0
        case .accessibility5:
            return -0
        @unknown default:
            return -0
        }
    }

    static func inboxTipXOffset(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium, .large, .xLarge:
            return -60
        case .xxLarge:
            return -60
        case .xxxLarge:
            return -60
        case .accessibility1:
            return -60
        case .accessibility2:
            return -60
        case .accessibility3:
            return -60
        case .accessibility4:
            return -60
        case .accessibility5:
            return -60
        @unknown default:
            return -60
        }
    }
}
