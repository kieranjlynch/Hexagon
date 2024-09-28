//
//  FloatingActionButton.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import TipKit

enum FloatingActionButtonItem: Identifiable {
    case addReminder
    case addNewList
    case addSubHeading
    case edit
    case delete
    case schedule
    
    var id: String { String(describing: self) }
    
    var label: String {
        switch self {
        case .addReminder: return "Add Task"
        case .addNewList: return "Add List"
        case .addSubHeading: return "Add Sub-Heading"
        case .edit: return "Edit"
        case .delete: return "Delete"
        case .schedule: return "Schedule"
        }
    }
    
    var icon: String {
        switch self {
        case .addReminder: return "checkmark.rectangle.stack"
        case .addNewList: return "list.bullet.rectangle.fill"
        case .addSubHeading: return "text.badge.plus"
        case .edit: return "pencil"
        case .delete: return "trash"
        case .schedule: return "calendar"
        }
    }
}

struct FloatingActionButton<TipContent: Tip>: View {
    @AppStorage("preferredTaskType") private var preferredTaskType: String = "Tasks"
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    private let appSettings: AppSettings
    
    @Binding var showTip: Bool
    let tip: TipContent?
    let onTapGesture: (() -> Void)?
    let menuItems: [FloatingActionButtonItem]
    let onMenuItemSelected: (FloatingActionButtonItem) -> Void

    private let sides = 6
    private let angle = 2 * .pi / CGFloat(6)

    init(appSettings: AppSettings, showTip: Binding<Bool> = .constant(false), tip: TipContent? = nil, onTapGesture: (() -> Void)? = nil, menuItems: [FloatingActionButtonItem], onMenuItemSelected: @escaping (FloatingActionButtonItem) -> Void) {
        self.appSettings = appSettings
        self._showTip = showTip
        self.tip = tip
        self.onTapGesture = onTapGesture
        self.menuItems = menuItems
        self.onMenuItemSelected = onMenuItemSelected
    }

    private func pointFrom(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        let x = center.x + radius * cos(angle)
        let y = center.y + radius * sin(angle)
        return CGPoint(x: x, y: y)
    }

    private func hexagonPath(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        let adjustment = CGFloat.pi / 6
        let startPoint = self.pointFrom(center: center, radius: radius, angle: -CGFloat.pi / 2 + adjustment)
        path.move(to: startPoint)

        for i in 1..<sides {
            let currentAngle = angle * CGFloat(i) - CGFloat.pi / 2 + adjustment
            let point = self.pointFrom(center: center, radius: radius, angle: currentAngle)
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                Color.clear

                Menu {
                    ForEach(menuItems) { item in
                        Button {
                            onMenuItemSelected(item)
                        } label: {
                            Label(item.label, systemImage: item.icon)
                        }
                        .accessibilityLabel(item.label)
                        .accessibilityHint("Tap to \(item.label.lowercased())")
                    }
                } label: {
                    hexagonButton
                        .frame(width: 50, height: 50)
                        .accessibilityLabel("Actions menu")
                        .accessibilityHint("Tap to open the actions menu")
                }
                .offset(x: -16, y: -16)
                .overlay(alignment: .topTrailing) {
                    if let tip = tip, showTip {
                        TipView(tip)
                            .frame(minWidth: 300)
                            .padding()
                            .offset(x: -60, y: tipOffset())
                            .transition(.opacity)
                    }
                }
                .onTapGesture {
                    onTapGesture?()
                }
            }
        }
    }

    private var hexagonButton: some View {
        Button(action: {
        }) {
            GeometryReader { geometry in
                ZStack {
                    hexagonPath(in: geometry.frame(in: .local))
                        .stroke(appSettings.appTintColor, lineWidth: 2)

                    Image(systemName: "plus")
                        .foregroundColor(appSettings.appTintColor)
                        .font(.system(size: 24))
                        .scaledToFit()
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Actions menu")
        .accessibilityHint("Double-tap to open the actions menu")
    }

    private func tipOffset() -> CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium, .large, .xLarge:
            return -45
        case .xxLarge:
            return -55
        case .xxxLarge:
            return -55
        case .accessibility1:
            return -80
        case .accessibility2:
            return -125
        case .accessibility3:
            return -150
        case .accessibility4:
            return -150
        case .accessibility5:
            return -150
        @unknown default:
            return -75
        }
    }
}
