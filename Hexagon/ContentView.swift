//
//  ContentView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import CoreData
import TipKit
import HexagonData

struct ContentView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var reminderService: ReminderService
    @EnvironmentObject var locationService: LocationService
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var selectedTab: String
    @State private var selectedListID: NSManagedObjectID?
    
    @State private var showFloatingActionButtonTip = true
    @State private var showInboxTip = false
    @State private var selectedView: String? = "Lists"
    @State private var previousSelectedTab: String = "Lists"
    
    private let floatingActionButtonTip = FloatingActionButtonTip()
    private let inboxTip = InboxTip()
    
    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                tabViewLayout
            } else {
                splitViewLayout
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if oldValue != newValue {
                handleTabChange(from: oldValue, to: newValue)
            }
        }
        .environment(\.appTintColor, appSettings.appTintColor)
        .font(.body)
        .onAppear {
            print("ReminderService in ContentView: \(reminderService)")
        }
    }

    private var tabViewLayout: some View {
        TabView(selection: $selectedTab) {
            settingsTab
                .adaptiveForegroundAndBackground()
                .adaptiveToolbarBackground()
            
            searchTab
                .adaptiveForegroundAndBackground()
                .adaptiveToolbarBackground()
            
            timelineTab
                .adaptiveForegroundAndBackground()
                .adaptiveToolbarBackground()
            
            inboxTab
                .adaptiveForegroundAndBackground()
                .adaptiveToolbarBackground()
            
            listsTab
                .adaptiveForegroundAndBackground()
                .adaptiveToolbarBackground()
        }
    }
    
    private var splitViewLayout: some View {
        NavigationSplitView {
            List(selection: $selectedView) {
                NavigationLink("Lists", value: "Lists")
                NavigationLink("Inbox", value: "Inbox")
                NavigationLink("Settings", value: "Settings")
                NavigationLink("Search", value: "Search")
                NavigationLink("Timeline", value: "Timeline")
            }
            .listSettings()
        } detail: {
            Group {
                switch selectedView {
                case "Lists":
                    listsView
                        .navigationBarSetup(title: "Lists")
                case "Inbox":
                    inboxView
                        .navigationBarSetup(title: "Inbox")
                case "Settings":
                    settingsView
                        .navigationBarSetup(title: "Settings")
                case "Search":
                    searchView
                        .navigationBarSetup(title: "Search")
                case "Timeline":
                    timelineView
                        .navigationBarSetup(title: "Timeline")
                default:
                    listsView
                        .navigationBarSetup(title: "Lists")
                }
            }
        }
    }
    
    private var settingsTab: some View {
        settingsView
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag("Settings")
            .accessibilityLabel(Text("Settings Tab"))
            .accessibilityHint(Text("Navigate to settings"))
    }
    
    private var searchTab: some View {
        searchView
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag("Search")
            .accessibilityLabel(Text("Search Tab"))
            .accessibilityHint(Text("Navigate to search"))
    }
    
    private var timelineTab: some View {
        timelineView
            .tabItem {
                Label("Timeline", systemImage: "calendar.day.timeline.left")
            }
            .tag("Timeline")
            .accessibilityLabel(Text("Timeline Tab"))
            .accessibilityHint(Text("Navigate to your timeline"))
    }
    
    private var inboxTab: some View {
        inboxView
            .tabItem {
                Label("Inbox", systemImage: "tray")
            }
            .tag("Inbox")
            .accessibilityLabel(Text("Inbox Tab"))
            .accessibilityHint(Text("Navigate to inbox"))
    }
    
    private var listsTab: some View {
        listsView
            .tabItem {
                Label("Lists", systemImage: "list.bullet")
            }
            .tag("Lists")
            .accessibilityLabel(Text("Lists Tab"))
            .accessibilityHint(Text("Navigate to your lists"))
    }
    
    private var settingsView: some View {
        SettingsView()
            .environmentObject(appSettings)
    }
    
    private var searchView: some View {
        SearchView()
            .environmentObject(reminderService)
            .environmentObject(locationService)
            .environmentObject(appSettings)
    }
    
    private var inboxView: some View {
        InboxView()
            .environmentObject(reminderService)
            .environmentObject(locationService)
    }
    
    private var listsView: some View {
        ListsView(
            selectedListID: $selectedListID,
            showFloatingActionButtonTip: $showFloatingActionButtonTip,
            showInboxTip: $showInboxTip,
            floatingActionButtonTip: floatingActionButtonTip,
            inboxTip: inboxTip
        )
        .environmentObject(reminderService)
        .environmentObject(locationService)
        .environmentObject(appSettings)
        .errorAlert(errorMessage: $appSettings.errorMessage, isPresented: $appSettings.isErrorPresented)
    }
    
    private var timelineView: some View {
        TimelineView()
            .environmentObject(reminderService)
            .environmentObject(locationService)
            .environmentObject(appSettings)
    }
    
    private func handleTabChange(from oldValue: String, to newValue: String) {
        if newValue != "Lists" {
            selectedListID = nil
        }
        if newValue == "Inbox" {
            showInboxTip = false
        }
    }
}
