//
//  HexagonApp.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import UserNotifications
import CoreData
import AppIntents
import os
import UIKit
import MapKit
import TipKit
import HexagonData

@main
struct Hexagon: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var locationService = LocationService()
    @StateObject private var reminderService = ReminderService.shared
    @StateObject private var appSettings = AppSettings()
    @StateObject private var listService = ListService.shared
    
    @State private var quickActionDestination: QuickActionDestination?
    @State private var selectedTab: String = "Lists"
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    @State private var isCoreDataInitialized = false
    
    private var logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.hexagon", category: "AppLifecycle")
    
    init() {
        logger.info("App initialization started")
        registerTransformers()
        logger.info("App initialization completed")
        
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !isCoreDataInitialized {
                    ProgressView("Loading...")
                } else if !hasLaunchedBefore {
                    WelcomeView()
                        .environmentObject(appSettings)
                        .environmentObject(reminderService)
                        .environmentObject(locationService)
                        .environmentObject(listService)
                } else {
                    ContentView(selectedTab: $selectedTab)
                        .environment(\.managedObjectContext, PersistenceController.shared.persistentContainer.viewContext)
                        .environmentObject(reminderService)
                        .environmentObject(locationService)
                        .environmentObject(appSettings)
                        .environmentObject(listService)
                        .onAppear {
                            print("ReminderService initialized: \(reminderService)")
                            setupGlobalTint()
                            setupQuickActionObserver()
                            updateDynamicQuickActions()
                        }
                        .task { try? Tips.resetDatastore() }
                        .onOpenURL { url in
                            handleQuickAction(url)
                        }
                        .sheet(item: $quickActionDestination) { destination in
                            if destination == .addTask {
                                AddReminderView(reminder: nil)
                                    .environmentObject(reminderService)
                                    .environmentObject(appSettings)
                            }
                        }
                }
            }
            .task {
                await initializeCoreDataAsync()
                isCoreDataInitialized = true
            }
        }
        .commands {
            CommandGroup(after: .appSettings) {
                Button("Add Task") {
                    quickActionDestination = .addTask
                }
            }
        }
        .handlesExternalEvents(matching: Set(["addTask"]))
    }
    
    private func initializeCoreDataAsync() async {
        do {
            try await PersistenceController.shared.initialize()
            logger.info("Core Data initialized successfully")
            checkTaskLists()
        } catch {
            logger.error("Core Data initialization failed: \(error.localizedDescription)")
        }
    }
    
    private func setupGlobalTint() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        window.tintColor = UIColor(appSettings.appTintColor)
        
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak window, weak appSettings] _ in
            if let appSettings = appSettings, let window = window {
                window.tintColor = UIColor(appSettings.appTintColor)
            }
        }
    }
    
    private func registerTransformers() {
        logger.info("Registering value transformers")
        if !ValueTransformer.valueTransformerNames().contains(NSValueTransformerName("UIColorTransformer")) {
            ValueTransformer.setValueTransformer(UIColorTransformer(), forName: NSValueTransformerName("UIColorTransformer"))
        } else {
            logger.info("UIColorTransformer already registered")
        }
    }
    
    private func setupQuickActionObserver() {
        NotificationCenter.default.addObserver(forName: .handleQuickAction, object: nil, queue: .main) { notification in
            if let shortcutItem = notification.object as? UIApplicationShortcutItem {
                Task { @MainActor in
                    handleShortcutAction(shortcutItem)
                }
            }
        }
    }
    
    @MainActor
    private func handleQuickAction(_ input: Any) {
        if let url = input as? URL {
            Task { await handleDeepLink(url) }
        } else if let shortcutItem = input as? UIApplicationShortcutItem {
            handleShortcutAction(shortcutItem)
        }
    }
    
    @MainActor
    private func handleDeepLink(_ url: URL) async {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        let host = components?.host
        
        switch host {
        case "addTask":
            quickActionDestination = .addTask
        case "openInbox":
            selectedTab = "Inbox"
        case "openSavedSearch":
            if let filterName = components?.queryItems?.first(where: { $0.name == "name" })?.value,
               let _ = await loadSavedFilter(name: filterName) {
                selectedTab = "Search"
            }
        default:
            break
        }
    }
    
    @MainActor
    private func handleShortcutAction(_ shortcutItem: UIApplicationShortcutItem) {
        switch shortcutItem.type {
        case "AddTaskAction":
            quickActionDestination = .addTask
        case "OpenInboxAction":
            selectedTab = "Inbox"
        default:
            if shortcutItem.type.hasPrefix("SavedSearch_"),
               let userInfo = shortcutItem.userInfo as? [String: String],
               let filterName = userInfo["name"] {
                Task {
                    if (await loadSavedFilter(name: filterName)) != nil {
                        selectedTab = "Search"
                    }
                }
            }
        }
    }

    @MainActor
    private func updateDynamicQuickActions() {
        Task {
            let savedFilters = await loadSavedFilters()
            let dynamicActions = savedFilters.prefix(2).map { filter in
                UIApplicationShortcutItem(
                    type: "SavedSearch_\(filter.id.uuidString)",
                    localizedTitle: filter.name,
                    localizedSubtitle: "Open saved search",
                    icon: UIApplicationShortcutIcon(systemImageName: "magnifyingglass"),
                    userInfo: ["name": filter.name as NSSecureCoding]
                )
            }
            
            let staticActions = UIApplication.shared.shortcutItems?.filter {
                $0.type == "AddTaskAction" || $0.type == "OpenInboxAction"
            } ?? []
            
            UIApplication.shared.shortcutItems = staticActions + dynamicActions
        }
    }
    
    func checkTaskLists() {
        let context = PersistenceController.shared.persistentContainer.viewContext
        let request: NSFetchRequest<TaskList> = TaskList.fetchRequest()
        
        do {
            let count = try context.count(for: request)
            print("Number of TaskList objects: \(count)")
            
        } catch {
            print("Error checking TaskLists: \(error)")
        }
    }
    
    private func loadSavedFilters() async -> [SavedFilter] {
        if let data = UserDefaults.standard.data(forKey: "SavedFilters") {
            do {
                return try JSONDecoder().decode([SavedFilter].self, from: data)
            } catch {
                return []
            }
        }
        return []
    }
    
    private func loadSavedFilter(name: String) async -> SavedFilter? {
        let savedFilters = await loadSavedFilters()
        return savedFilters.first { $0.name == name }
    }
}

public enum QuickActionDestination: Identifiable {
    case addTask
    
    public var id: String {
        return "addTask"
    }
}
