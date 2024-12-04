//
//  AppDelegate.swift
//  Hexagon
//
//  Created by Kieran Lynch on 06/09/2024.
//

import UIKit
import SwiftUI
import WidgetKit
import CoreData

class AppDelegate: NSObject, UIApplicationDelegate {
    private let listService = ListService.shared
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UserDefaults.standard.register(defaults: [
            "maxTasksStartedPerDay": 3,
            "maxTasksCompletedPerDay": 5,
            "isStartLimitUnlimited": true,
            "isCompletionLimitUnlimited": true
        ])
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        handleURL(url)
        return true
    }
    
    @MainActor public func updateDynamicQuickActions() {
        Task {
            do {
                let recentLists = try await listService.fetchRecentLists(limit: 1)
                var shortcutItems = UIApplication.shared.shortcutItems ?? []
                shortcutItems.removeAll { $0.type == "OpenListAction" }
                for list in recentLists {
                    guard let name = list.name,
                          !name.isEmpty,
                          let listId = list.listID?.uuidString else {
                        continue
                    }
                    let item = UIApplicationShortcutItem(
                        type: "OpenListAction",
                        localizedTitle: name,
                        localizedSubtitle: "Open list",
                        icon: UIApplicationShortcutIcon(systemImageName: list.symbol ?? "list.bullet"),
                        userInfo: ["listId": listId as NSString]
                    )
                    shortcutItems.insert(item, at: 0)
                }
                
                await MainActor.run {
                    UIApplication.shared.shortcutItems = shortcutItems
                }
            } catch {
            }
        }
    }
    
    private func handleURL(_ url: URL) {
        guard url.scheme == "hexagon" else { return }
        
        NotificationCenter.default.post(
            name: .handleQuickAction,
            object: UIApplicationShortcutItem(
                type: "AddTaskAction",
                localizedTitle: "Add Task"
            )
        )
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        DateFormatter.updateSharedDateFormatter()
        
        if let shortcutItem = connectionOptions.shortcutItem {
            handleQuickAction(shortcutItem)
        }
        
        if let urlContext = connectionOptions.urlContexts.first {
            handleURL(urlContext.url)
        }
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            Task { @MainActor in
                appDelegate.updateDynamicQuickActions()
            }
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleURL(url)
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        DateFormatter.updateSharedDateFormatter()
    }
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        handleQuickAction(shortcutItem)
        completionHandler(true)
    }
    
    private func handleQuickAction(_ shortcutItem: UIApplicationShortcutItem) {
        switch shortcutItem.type {
        case "AddTaskAction":
            NotificationCenter.default.post(name: .handleQuickAction, object: shortcutItem)
        case "TodayAction":
            NotificationCenter.default.post(name: .switchTab, object: "Today")
        case "UpcomingAction":
            NotificationCenter.default.post(name: .switchTab, object: "Upcoming")
        case "OpenListAction":
            if let userInfo = shortcutItem.userInfo as? [String: NSString],
               let listIdString = userInfo["listId"] as? String,
               let uuid = UUID(uuidString: listIdString) {
                handleListOpening(uuid: uuid)
            }
            else {
                Task {
                    do {
                        let recentLists = try await ListService.shared.fetchRecentLists(limit: 1)
                        if let list = recentLists.first,
                           let listId = list.listID {
                            await MainActor.run {
                                handleListOpening(uuid: listId)
                            }
                        }
                    } catch {
                    }
                }
            }
        default:
            print("❌ SceneDelegate: Unknown action type")
        }
    }
    
    private func handleListOpening(uuid: UUID) {
        let context = PersistenceController.shared.persistentContainer.viewContext
        let request: NSFetchRequest<TaskList> = TaskList.fetchRequest()
        request.predicate = NSPredicate(format: "listID == %@", uuid as CVarArg)
        request.fetchLimit = 1
        
        if let list = try? context.fetch(request).first {
            NotificationCenter.default.post(name: .switchTab, object: "Lists")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .selectList, object: list)
            }
        } else {
        }
    }
    
    private func handleURL(_ url: URL) {
        guard url.scheme == "hexagon" else {
            return
        }
        if url.host == "addTask" {
            NotificationCenter.default.post(
                name: .handleQuickAction,
                object: UIApplicationShortcutItem(
                    type: "AddTaskAction",
                    localizedTitle: "Add Task"
                )
            )
        } else {
        }
    }
}
