//
//  Constants.swift
//  Hexagon
//
//  Created by Kieran Lynch on 11/09/2024.
//

import SwiftUI
import MapKit

enum Constants {
    enum General {
        static let appName = "Hexagon"
        static let appBundleIdentifier = "com.hexagon"
    }
    
    enum Animation {
        static let defaultDuration: Double = 0.3
        static let quickDuration: Double = 0.2
        static let expandedScale: CGFloat = 1.1
    }
    
    enum Calendar {
        static let minDuration: Double = 15
        static let maxDuration: Double = 240
        static let defaultDuration: Double = 60
    }
    
    enum UI {
        static let horizontalPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 4
        static let iconSize: CGFloat = 24
        static let buttonVerticalPadding: CGFloat = 8
        static let thumbnailHeight: CGFloat = 100
        static let borderWidth: CGFloat = 1
        static let mapSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        static let mapHeight: CGFloat = 0.5
        static let shadowRadius: CGFloat = 2
        static let cardMinHeight: CGFloat = 80
        static let cardPadding: CGFloat = 16
        static let maxTitleWidth: CGFloat = 200
        static let listCardHeight: CGFloat = 80
        static let searchBarHeight: CGFloat = 36
        static let floatingButtonSize: CGFloat = 60
        static let floatingButtonPadding: CGFloat = 16
    }
    
    enum Colors {
        static let backgroundColor = Color("1B1B1E")
    }
    
    enum Strings {
        static let noTasksAvailable = "No tasks available"
        static let addNewTask = "Add New Task"
        static let settings = "Settings"
        static let search = "Search"
        static let inbox = "Inbox"
        static let lists = "Lists"
        static let searchResultsHeader = "Search Results"
        static let saveButton = "Save"
        static let cancelButton = "Cancel"
    }
    
    enum UserDefaultsKeys {
        static let hasLaunchedBefore = "hasLaunchedBefore"
        static let appTintColorRed = "appTintColorRed"
        static let appTintColorGreen = "appTintColorGreen"
        static let appTintColorBlue = "appTintColorBlue"
    }
    
    enum NotificationNames {
        static let reminderAdded = "reminderAdded"
        static let handleQuickAction = "HandleQuickAction"
    }
}
