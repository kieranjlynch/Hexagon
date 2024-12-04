//
//  DragStateManager.swift
//  Hexagon
//
//  Created by Kieran Lynch on 19/11/2024.
//

import SwiftUI
import Combine
import os

@MainActor
class DragStateManager: ObservableObject {
    @Published var draggingListItem: ListItemTransfer?
    @Published var targetIndex: Int?
    @Published var targetSubheadingID: UUID?
    @Published private(set) var dragState: DragState = .inactive

    private var logger = Logger(subsystem: "com.hexagon.app", category: "DragStateManager")
    private var dragStartTime: Date?
    private var dragTimeout: TimeInterval = 0.5

    enum DragState: Equatable {
        case inactive
        case dragging(ListItemTransfer)

        static func == (lhs: DragState, rhs: DragState) -> Bool {
            switch (lhs, rhs) {
            case (.inactive, .inactive):
                return true
            case let (.dragging(item1), .dragging(item2)):
                return item1.id == item2.id
            default:
                return false
            }
        }
    }

    static let shared = DragStateManager()
    private init() {}

    @MainActor
    func startDragging(item: ListItemTransfer) {
        let now = Date()

        if let startTime = dragStartTime {
            let elapsed = now.timeIntervalSince(startTime)
            if elapsed < dragTimeout {
                return
            }
        }

        dragStartTime = now
        draggingListItem = item
        dragState = .dragging(item)
    }

    @MainActor
    func setDropTarget(index: Int?, subheadingID: UUID?) {
        targetIndex = index
        targetSubheadingID = subheadingID
    }

    @MainActor
    func endDragging() {
        dragStartTime = nil
        draggingListItem = nil
        targetIndex = nil
        targetSubheadingID = nil
        dragState = .inactive
    }
}
