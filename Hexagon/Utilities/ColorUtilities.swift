//
//  ColorUtilities.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI

// MARK: - Color Extensions

extension Color {

    
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &o)
        return (r, g, b, o)
    }
}

// MARK: - UIColor Extensions

extension UIColor {
    static func fromHex(_ hex: String) -> UIColor? {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        
        guard hexString.count == 6 || hexString.count == 8 else { return nil }
        
        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)
        
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0
        let a = hexString.count == 8 ? CGFloat((rgb >> 24) & 0xFF) / 255.0 : 1.0
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    func toHex(includeAlpha: Bool = true) -> String? {
        guard let components = cgColor.components, components.count >= 3 else { return nil }
        let r = components[0]
        let g = components[1]
        let b = components[2]
        let a = components.count > 3 ? components[3] : 1.0
        
        if includeAlpha {
            return String(format: "#%02X%02X%02X%02X",
                          Int(a * 255),
                          Int(r * 255),
                          Int(g * 255),
                          Int(b * 255))
        } else {
            return String(format: "#%02X%02X%02X",
                          Int(r * 255),
                          Int(g * 255),
                          Int(b * 255))
        }

    }
    
    static func color(data: Data) -> UIColor? {
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)
    }
}
