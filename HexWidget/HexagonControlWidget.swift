//
//  HexagonControlWidget.swift
//  HexWidget
//
//  Created by Kieran Lynch on 08/11/2024.
//

import SwiftUI
import WidgetKit
import AppIntents

@available(iOS 18.0, *)
struct HexagonControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.hexagon.addtask") {
            ControlWidgetButton(action: AddTaskIntent()) {
                Label("Add Task", systemImage: "plus.circle.fill")
            } actionLabel: { isPressed in
                if isPressed {
                    Label("Adding Task...", systemImage: "plus.circle.fill")
                } else {
                    Label("Add Task", systemImage: "plus.circle.fill")
                }
            }
        }
        .displayName("Quick Add Task")
        .description("Quickly add a new task from anywhere")
    }
}
