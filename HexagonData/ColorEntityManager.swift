//
//  ColorEntityManager.swift
//  HexagonData
//
//  Created by Kieran Lynch on 19/09/2024.
//

import SwiftUI
import AppIntents
import UIKit
import Foundation

public struct ColorEntity: AppEntity, Identifiable {
    public let id: UUID
    public let color: Color

    public init(id: UUID, color: Color) {
        self.id = id
        self.color = color
    }

    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Color")
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: colorDescription(color),
            image: .init(systemName: "paintpalette.fill")
        )
    }

    public static var defaultQuery = ColorQuery()
}

public struct ColorQuery: EntityQuery {
    public init() {}
    
    public func entities(for identifiers: [UUID]) async throws -> [ColorEntity] {
        let allColors = try await suggestedEntities()
        return allColors.filter { identifiers.contains($0.id) }
    }

    public func suggestedEntities() async throws -> [ColorEntity] {
        [
            ColorEntity(id: UUID(), color: .red),
            ColorEntity(id: UUID(), color: .blue),
            ColorEntity(id: UUID(), color: .green),
            ColorEntity(id: UUID(), color: .yellow)
        ]
    }
}

public func colorDescription(_ color: Color) -> LocalizedStringResource {
    switch color {
    case .red: return LocalizedStringResource("Red")
    case .blue: return LocalizedStringResource("Blue")
    case .green: return LocalizedStringResource("Green")
    case .yellow: return LocalizedStringResource("Yellow")
    default: return LocalizedStringResource("Custom Color")
    }
}

public class UIColorTransformer: ValueTransformer {
    public override class func allowsReverseTransformation() -> Bool {
        return true
    }

    public override func transformedValue(_ value: Any?) -> Any? {
        guard let color = value as? UIColor else { return nil }

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
            return data
        } catch {
            return nil
        }
    }

    public override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }

        do {
            let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)
            return color
        } catch {
            return nil
        }
    }
}

public extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = hex.startIndex
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

public struct AppColors {
    public static let backgroundColor = Color(hex: "1B1B1E")
    public static let defaultAppTintColor: Color = .orange
}

public struct AppTintColorKey: EnvironmentKey {
    public static let defaultValue: Color = AppColors.defaultAppTintColor
}

public extension EnvironmentValues {
    var appTintColor: Color {
        get { self[AppTintColorKey.self] }
        set { self[AppTintColorKey.self] = newValue }
    }
}
