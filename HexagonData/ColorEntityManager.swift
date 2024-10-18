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

public struct ColorManager: AppEntity, Identifiable, Codable {
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

    public enum CodingKeys: String, CodingKey {
        case id, color
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        let colorComponents = try container.decode([CGFloat].self, forKey: .color)
        color = Color(red: colorComponents[0], green: colorComponents[1], blue: colorComponents[2], opacity: colorComponents[3])
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        try container.encode([red, green, blue, alpha], forKey: .color)
    }
}

public struct ColorQuery: EntityQuery {
    public init() {}
    
    public func entities(for identifiers: [UUID]) async throws -> [ColorManager] {
        let allColors = try await suggestedEntities()
        return allColors.filter { identifiers.contains($0.id) }
    }

    public func suggestedEntities() async throws -> [ColorManager] {
        [
            ColorManager(id: UUID(), color: .red),
            ColorManager(id: UUID(), color: .blue),
            ColorManager(id: UUID(), color: .green),
            ColorManager(id: UUID(), color: .yellow)
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

public struct AppColors {
    public static let backgroundColor = Color("1B1B1E")
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
