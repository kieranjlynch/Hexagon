//
//  HexagonTips.swift
//  Hexagon
//
//  Created by Kieran Lynch on 08/09/2024.
//

import SwiftUI
import TipKit

struct FloatingActionButtonTip: Tip {
    var title: Text {
        Text("Add Lists or \(preferredTaskType)")
    }
    
    var message: Text? {
        Text("Tap the Hexagon")
    }
    
    private var preferredTaskType: String {
        UserDefaults.standard.string(forKey: "preferredTaskType") ?? "Tasks"
    }
}

struct InboxTip: Tip {
    var title: Text {
        Text("Inbox")
    }
    
    var message: Text? {
        Text("For \(preferredTaskType) that aren't assigned to lists.")
    }
    
    private var preferredTaskType: String {
        UserDefaults.standard.string(forKey: "preferredTaskType") ?? "Tasks"
    }
}

struct EmptyTip: Tip {
    var title: Text {
        Text("")
    }
    var message: Text? {
        nil
    }
}
