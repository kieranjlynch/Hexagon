//
//  ContentView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import CoreData
import TipKit

import UIKit

struct ContentView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var selectedTab: String
    @State private var selectedList: TaskList?
    @State private var selectedListID: NSManagedObjectID?
    
    @State private var showFloatingActionButtonTip = true
    @State private var showInboxTip = false
    @State private var selectedView: String? = "Lists"
    @State private var previousSelectedTab: String = "Lists"
    
    private let floatingActionButtonTip = FloatingActionButtonTip()
    private let inboxTip = InboxTip()
    
    private let fetchingService = ReminderFetchingServiceUI.shared
    private let modificationService = ReminderModificationService.shared
    private let listService = ListService.shared
    private let subheadingService = SubheadingService.shared
    private let tagService = TagService.shared
    private let performanceMonitor = PerformanceMonitor()
    
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
        .onReceive(NotificationCenter.default.publisher(for: .selectList)) { notification in
            if let objectID = notification.object as? NSManagedObjectID,
               let list = try? viewContext.existingObject(with: objectID) as? TaskList {
                selectedTab = "Lists"
                selectedList = list
                selectedListID = objectID
                
                navigateToList(list)
            }
        }
        .environment(\.appTintColor, appSettings.appTintColor)
        .font(.body)
        .environmentObject(fetchingService)
        .environmentObject(modificationService)
        .environmentObject(listService)
        .environmentObject(subheadingService)
        .environmentObject(tagService)
    }
    
    private func navigateToList(_ list: TaskList) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController,
              let tabBarController = rootViewController as? UITabBarController else {
            return
        }

        tabBarController.selectedIndex = 3

        if let navigationController = tabBarController.selectedViewController as? UINavigationController {
            let viewModel = ListDetailViewModel(
                taskList: list,
                reminderService: fetchingService.service,
                subHeadingService: subheadingService,
                performanceMonitor: performanceMonitor as PerformanceMonitoring
            )

            let listDetailView = ListDetailView(
                viewModel: viewModel,
                showFloatingActionButtonTip: .constant(false),
                floatingActionButtonTip: floatingActionButtonTip
            )
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(appSettings)
                .environmentObject(DragStateManager.shared) 

            let hostingController = UIHostingController(rootView: listDetailView)
            navigationController.pushViewController(hostingController, animated: true)
        }
    }
    
    private var tabViewLayout: some View {
        TabView(selection: $selectedTab) {
            historyTab
                .adaptiveForegroundAndBackground()
                .adaptiveToolbarBackground()
            
            upcomingTab
                .adaptiveForegroundAndBackground()
                .adaptiveToolbarBackground()
            
            todayTab
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
                NavigationLink("Upcoming", value: "Upcoming")
            }
            .listSettings()
        } detail: {
            Group {
                switch selectedView {
                case "Lists":
                    listsView
                        .navigationBarSetup(title: "Lists")
                case "Upcoming":
                    upcomingView
                        .navigationBarSetup(title: "Upcoming")
                default:
                    listsView
                        .navigationBarSetup(title: "Lists")
                }
            }
        }
    }
    
    private var todayTab: some View {
        TodayView()
            .environmentObject(appSettings)
            .tabItem {
                Label("Today", systemImage: "calendar")
            }
            .tag("Today")
            .accessibilityLabel(Text("Today Tab"))
            .accessibilityHint(Text("View today's tasks"))
    }
    
    
    private var historyTab: some View {
        HistoryView(
            context: viewContext,
            fetchingService: fetchingService.service,
            modificationService: modificationService,
            subheadingService: subheadingService
        )
        .environmentObject(appSettings)
        .tabItem {
            Label("History", systemImage: "clock.arrow.circlepath")
        }
        .tag("History")
    }
    
    private var upcomingTab: some View {
        upcomingView
            .tabItem {
                Label("Upcoming", systemImage: "calendar.day.timeline.left")
            }
            .tag("Upcoming")
            .accessibilityLabel(Text("Upcoming Tab"))
            .accessibilityHint(Text("Navigate to your Upcoming tasks"))
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
    
    private var listsView: some View {
        ListsView(
            context: viewContext,
            fetchingService: fetchingService,
            modificationService: modificationService,
            subheadingService: subheadingService,
            showFloatingActionButtonTip: $showFloatingActionButtonTip,
            showInboxTip: $showInboxTip,
            floatingActionButtonTip: floatingActionButtonTip,
            inboxTip: inboxTip
        )
        .errorAlert(errorMessage: $appSettings.errorMessage, isPresented: $appSettings.isErrorPresented)
    }
    
    private var upcomingView: some View {
        UpcomingView(fetchingService: fetchingService.service, listService: listService)
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
