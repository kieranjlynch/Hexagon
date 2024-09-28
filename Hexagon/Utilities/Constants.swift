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
    
    enum UI {
        static let horizontalPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 4
        static let iconSize: CGFloat = 24
        static let buttonVerticalPadding: CGFloat = 8
        static let thumbnailHeight: CGFloat = 100
        static let borderWidth: CGFloat = 1
        static let mapSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        static let mapHeight: CGFloat = 0.5
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
        static let fetchingLocation = "Fetching location..."
        static let searchPlaceholder = "Search for a location"
        static let searchResultsHeader = "Search Results"
        static let saveLocationButton = "Save Location"
        static let saveLocationAlertTitle = "Save Location"
        static let saveLocationAlertMessage = "Enter a name for this location"
        static let saveButton = "Save"
        static let cancelButton = "Cancel"
        static let unknownLocation = "Unknown location"
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
