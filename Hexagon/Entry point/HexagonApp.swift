// HexagonApp.swift
// Hexagon

import SwiftUI
import UserNotifications
import CoreData
import AppIntents
import os
import UIKit
import MapKit
import TipKit


public enum QuickActionDestination: Identifiable {
    case addTask
    case openList(listObjectID: NSManagedObjectID)
    
    public var id: String {
        switch self {
        case .addTask:
            return "addTask"
        case .openList(let listObjectID):
            return "openList-\(listObjectID.uriRepresentation().absoluteString)"
        }
    }
}

@main
struct Hexagon: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var fetchingService = ReminderFetchingServiceUI(service: ReminderFetchingService.shared)
    @StateObject private var appSettings = AppSettings()
    @StateObject private var listService = ListService()
    @StateObject private var dragStateManager = DragStateManager.shared
    @StateObject private var reminderModificationService = ReminderModificationService.shared
    @StateObject private var tagService = TagService.shared
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var quickActionDestination: QuickActionDestination?
    @State private var selectedTab: String = "Lists"
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    @State private var isCoreDataInitialized = false
    @State private var showICloudAlert = false
    @State private var initializationError: Error?
    @State private var isShowingError = false
    
    private var logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.hexagon", category: "AppLifecycle")
    
    init() {
        registerTransformers()
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !isCoreDataInitialized {
                    ProgressView("Syncing with iCloud")
                        .task(priority: .userInitiated) {
                            do {
                                try await PersistenceController.shared.initialize()
                                _ = try await listService.fetchInboxList()
                                await listService.initialize()
                                await MainActor.run {
                                    isCoreDataInitialized = true
                                }
                            } catch {
                                logger.error("Core Data initialization failed: \(error.localizedDescription)")
                                await MainActor.run {
                                    initializationError = error
                                    isShowingError = true
                                }
                            }
                        }
                } else {
                    mainContentView
                }
            }
            .alert("Initialization Error", isPresented: $isShowingError, presenting: initializationError) { _ in
                Button("Retry") {
                    isCoreDataInitialized = false
                }
                Button("Quit") {
                    exit(1)
                }
            } message: { error in
                Text(error.localizedDescription)
            }
            .onReceive(NotificationCenter.default.publisher(for: .handleQuickAction)) { notification in
                if let shortcutItem = notification.object as? UIApplicationShortcutItem {
                    if shortcutItem.type == "AddTaskAction" {
                        quickActionDestination = .addTask
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .switchTab)) { notification in
                if let tab = notification.object as? String {
                    selectedTab = tab
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    updateDynamicQuickActions()
                }
            }
            .environmentObject(dragStateManager)
            .environmentObject(reminderModificationService)
            .environmentObject(tagService)
            .environmentObject(fetchingService)
            .environmentObject(listService)
            .environmentObject(appSettings)
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        if !hasLaunchedBefore {
            WelcomeView()
                .environment(\.managedObjectContext, PersistenceController.shared.persistentContainer.viewContext)
        } else {
            ContentView(selectedTab: $selectedTab)
                .environment(\.managedObjectContext, PersistenceController.shared.persistentContainer.viewContext)
                .onAppear {
                    setupGlobalTint()
                    setupQuickActionObserver()
                }
                .onOpenURL { url in
                    handleQuickAction(url)
                }
                .sheet(item: $quickActionDestination) { destination in
                    switch destination {
                    case .addTask:
                        AddReminderView(
                            reminder: nil,
                            defaultList: nil,
                            persistentContainer: PersistenceController.shared.persistentContainer,
                            fetchingService: fetchingService,
                            modificationService: ReminderModificationService.shared,
                            tagService: TagService.shared,
                            listService: listService
                        )
                    case .openList(listObjectID: let listObjectID):
                        if let list = try? PersistenceController.shared.persistentContainer.viewContext.existingObject(with: listObjectID) as? TaskList {
                            AddReminderView(
                                reminder: nil,
                                defaultList: list,
                                persistentContainer: PersistenceController.shared.persistentContainer,
                                fetchingService: fetchingService,
                                modificationService: ReminderModificationService.shared,
                                tagService: TagService.shared,
                                listService: listService
                            )
                        }
                    }
                }
                .alert(isPresented: $showICloudAlert) {
                    Alert(
                        title: Text("iCloud Not Available"),
                        message: Text("You are not signed into iCloud. Your information is not being saved in the cloud."),
                        primaryButton: .default(Text("Open Settings")) {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        },
                        secondaryButton: .cancel(Text("Dismiss"))
                    )
                }
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
        if !ValueTransformer.valueTransformerNames().contains(NSValueTransformerName("UIColorTransformer")) {
            ValueTransformer.setValueTransformer(UIColorTransformer(), forName: NSValueTransformerName("UIColorTransformer"))
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
        let listIdParam = components?.queryItems?.first(where: { $0.name == "listId" })?.value
        
        switch host {
        case "addTask":
            if let listIdString = listIdParam,
               let listId = UUID(uuidString: listIdString) {
                let context = PersistenceController.shared.persistentContainer.viewContext
                let request: NSFetchRequest<TaskList> = TaskList.fetchRequest()
                request.predicate = NSPredicate(format: "listID == %@", listId as CVarArg)
                request.fetchLimit = 1
                if let defaultList = try? context.fetch(request).first {
                    quickActionDestination = .addTask
                    quickActionDestination = .openList(listObjectID: defaultList.objectID)
                } else {
                    quickActionDestination = .addTask
                }
            } else {
                quickActionDestination = .addTask
            }
        default:
            break
        }
    }
    
    private func updateDynamicQuickActions() {
        Task {
            let recentLists = try? await listService.fetchRecentLists(limit: 3)
            let dynamicItems: [UIApplicationShortcutItem] = recentLists?.compactMap { list in
                guard let name = list.name, !name.isEmpty else { return nil }
                let listID = list.listID?.uuidString ?? list.objectID.uriRepresentation().absoluteString
                return UIApplicationShortcutItem(
                    type: "OpenListAction",
                    localizedTitle: name,
                    localizedSubtitle: "Open list",
                    icon: UIApplicationShortcutIcon(systemImageName: list.symbol ?? "list.bullet"),
                    userInfo: ["listId": listID as NSString]
                )
            } ?? []
            
            let existingItems = UIApplication.shared.shortcutItems ?? []
            let staticItems = existingItems.filter { item in
                ["AddTaskAction", "TodayAction", "UpcomingAction"].contains(item.type)
            }
            
            await MainActor.run {
                UIApplication.shared.shortcutItems = staticItems + dynamicItems
            }
        }
    }
    
    @MainActor
    private func handleShortcutAction(_ shortcutItem: UIApplicationShortcutItem) {
        switch shortcutItem.type {
        case "AddTaskAction":
            quickActionDestination = .addTask
        case "TodayAction":
            selectedTab = "Today"
        case "UpcomingAction":
            selectedTab = "Upcoming"
        case "OpenListAction":
            if let listId = shortcutItem.userInfo?["listId"] as? String {
                let context = PersistenceController.shared.persistentContainer.viewContext
                if let url = URL(string: listId),
                   let objectID = PersistenceController.shared.persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) {
                    
                    selectedTab = "Lists"
                    NotificationCenter.default.post(name: .selectList, object: objectID)
                } else if let uuid = UUID(uuidString: listId) {
                    
                    let request: NSFetchRequest<TaskList> = TaskList.fetchRequest()
                    request.predicate = NSPredicate(format: "listID == %@", uuid as NSUUID)
                    request.fetchLimit = 1
                    if let list = try? context.fetch(request).first {
                        selectedTab = "Lists"
                        NotificationCenter.default.post(name: .selectList, object: list.objectID)
                    }
                }
            }
        default:
            break
        }
    }
}
