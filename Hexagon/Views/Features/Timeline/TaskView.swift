//
//  TaskView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/09/2024.
//

import SwiftUI
import HexagonData

struct TaskView: View {
    let task: TimelineTask

    var body: some View {
        Text(task.title)
            .padding(5)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(5)
    }
}
