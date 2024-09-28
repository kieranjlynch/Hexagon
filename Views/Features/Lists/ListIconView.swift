//
//  ListIconView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import UIKit
import HexagonData

struct ListIconView: View {
    @Environment(\.appTintColor) var appTintColor
    @Environment(\.colorScheme) var colorScheme
    let taskList: TaskList
    let onDelete: (TaskList) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: taskList.symbol ?? "list.bullet")
                .foregroundColor(Color(UIColor.color(data: taskList.colorData ?? Data()) ?? .gray))
            Text(taskList.name ?? "")
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            Spacer()
            Text("\(incompleteTasks.count)")
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                .padding(.trailing)
        }
        .contentShape(Rectangle())
        .onLongPressGesture {
            onDelete(taskList)
        }
    }
    
    private var incompleteTasks: [Reminder] {
        let allReminders = taskList.reminders?.allObjects as? [Reminder] ?? []
        return allReminders.filter { !$0.isCompleted }
    }
}
