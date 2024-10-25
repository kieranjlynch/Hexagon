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
    @EnvironmentObject var listService: ListService
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
        .onChange(of: selectedTab, initial: false) { oldValue, newValue in
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
            
            timelineTab
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
                case "Settings":
                    settingsView
                        .navigationBarSetup(title: "Settings")
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
    
    private var timelineTab: some View {
        timelineView
            .tabItem {
                Label("Timeline", systemImage: "calendar.day.timeline.left")
            }
            .tag("Timeline")
            .accessibilityLabel(Text("Timeline Tab"))
            .accessibilityHint(Text("Navigate to your timeline"))
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
    
    private var listsView: some View {
        ListsView(
            context: viewContext,
            reminderService: reminderService,
            showFloatingActionButtonTip: $showFloatingActionButtonTip,
            showInboxTip: $showInboxTip,
            floatingActionButtonTip: floatingActionButtonTip,
            inboxTip: inboxTip
        )
        .environmentObject(reminderService)
        .environmentObject(locationService)
        .environmentObject(appSettings)
        .environmentObject(listService)
        .errorAlert(errorMessage: $appSettings.errorMessage, isPresented: $appSettings.isErrorPresented)
    }
    
    private var timelineView: some View {
        TimelineView(reminderService: reminderService, listService: listService)
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
