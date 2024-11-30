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
    case move
    
    var id: String { String(describing: self) }
    
    var label: String {
        switch self {
        case .addReminder: return "Add Task"
        case .addNewList: return "Add List"
        case .addSubHeading: return "Add Sub-Heading"
        case .edit: return "Edit"
        case .delete: return "Delete"
        case .schedule: return "Schedule"
        case .move: return "Move to List"
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
        case .move: return "arrow.right.square"
        }
    }
}

struct FloatingActionButton<T: Tip>: View {
    @ObservedObject var appSettings: AppSettings
    @Binding var showTip: Bool
    let tip: T
    let menuItems: [FloatingActionButtonItem]
    let onMenuItemSelected: (FloatingActionButtonItem) -> Void
    
    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private let buttonSize: CGFloat = 60
    private let expandedScale: CGFloat = 1.1
    private let sides = 6
    private let angle = 2 * .pi / CGFloat(6)
    
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
        let startPoint = pointFrom(center: center, radius: radius, angle: -CGFloat.pi / 2 + adjustment)
        path.move(to: startPoint)
        
        for i in 1..<sides {
            let currentAngle = angle * CGFloat(i) - CGFloat.pi / 2 + adjustment
            let point = pointFrom(center: center, radius: radius, angle: currentAngle)
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                menuContent
            }
        }
        .animation(.spring(), value: isExpanded)
    }
    
    private var menuContent: some View {
            VStack(alignment: .trailing, spacing: 16) {
                if isExpanded {
                    expandedButtons
                }
                
                mainHexagonButton
                    .rotationEffect(.degrees(isExpanded ? 150 : 0))
                    .scaleEffect(isExpanded ? expandedScale : 1)
            }
            .transition(.scale)
        }
    
    private var expandedButtons: some View {
        VStack(alignment: .trailing, spacing: 12) {
            ForEach(menuItems) { item in
                FloatingActionMenuButton(
                    systemImage: item.icon,
                    label: item.label,
                    backgroundColor: appSettings.appTintColor
                ) {
                    withAnimation(.spring()) {
                        isExpanded = false
                        onMenuItemSelected(item)
                    }
                }
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    private var mainHexagonButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                isExpanded.toggle()
                if showTip {
                    showTip = false
                }
            }
        }) {
            GeometryReader { geometry in
                ZStack {
                    hexagonPath(in: geometry.frame(in: .local))
                        .fill(appSettings.appTintColor)
                        .shadow(radius: 4)
                    
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: buttonSize, height: buttonSize)
        .popoverTip(tip, arrowEdge: .top)
        .accessibilityLabel("Actions menu")
        .accessibilityHint("Double-tap to open the actions menu")
    }
}

struct FloatingActionMenuButton: View {
    let systemImage: String
    let label: String
    let backgroundColor: Color
    let action: () -> Void
    
    private let buttonSize: CGFloat = 50
    private let sides = 6
    private let angle = 2 * .pi / CGFloat(6)
    
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
        let startPoint = pointFrom(center: center, radius: radius, angle: -CGFloat.pi / 2 + adjustment)
        path.move(to: startPoint)
        
        for i in 1..<sides {
            let currentAngle = angle * CGFloat(i) - CGFloat.pi / 2 + adjustment
            let point = pointFrom(center: center, radius: radius, angle: currentAngle)
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                GeometryReader { geometry in
                    ZStack {
                        hexagonPath(in: geometry.frame(in: .local))
                            .fill(backgroundColor)
                            .shadow(radius: 4)
                        
                        Image(systemName: systemImage)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(width: buttonSize, height: buttonSize)
                
                Text(label)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 2)
            }
        }
    }
}
