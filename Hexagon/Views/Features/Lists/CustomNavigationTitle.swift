//
//  CustomNavigationTitle.swift
//  Hexagon
//
//  Created by Kieran Lynch on 23/10/2024.
//

import SwiftUI
import HexagonData

struct CustomNavigationTitle: View {
    let taskList: TaskList
    @Environment(\.colorScheme) private var colorScheme
    
    private var isInbox: Bool {
        taskList.name == "Inbox"
    }
    
    var body: some View {
        HStack(spacing: 8) {
            listIcon
            Text(taskList.name ?? "Unnamed List")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
    }
    
    private var listIcon: some View {
        Image(systemName: isInbox ? "tray.fill" : (taskList.symbol ?? "list.bullet"))
            .foregroundColor(isInbox ? .gray : Color(UIColor.color(data: taskList.colorData ?? Data()) ?? .gray))
            .font(.system(size: 20))
    }
}
