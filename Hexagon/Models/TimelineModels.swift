//
//  TimelineModels.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/09/2024.
//

import Foundation
import HexagonData

struct TimelineTask: Identifiable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date?
    let list: HexagonData.TaskList?
    let isCompleted: Bool
}

enum ListFilter: Hashable {
    case all
    case inbox
    case specificList(HexagonData.TaskList)
}

