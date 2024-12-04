//
//  Notification+Names.swift
//  Hexagon
//
//  Created by Kieran Lynch on 09/11/2024.
//

import Foundation

extension Notification.Name {
    static let handleQuickAction = Notification.Name("HandleQuickAction")
    static let switchTab = Notification.Name("SwitchTab")
    static let selectList = Notification.Name("SelectList")
    static let subheadingChanged = Notification.Name("subheadingChanged")
    static let dateFormatChanged = Notification.Name("dateFormatChanged")
    static let reminderDeleted = Notification.Name("reminderDeleted")
    static let reminderSaved = Notification.Name("reminderSaved")
    static let reminderStatusChanged = Notification.Name("reminderStatusChanged")
    static let forceOpenList = Notification.Name("forceOpenList")
}
