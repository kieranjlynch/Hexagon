//
//  AppDelegate.swift
//  Hexagon
//
//  Created by Kieran Lynch on 06/09/2024.
//

import UIKit
import SwiftUI
import WidgetKit


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        fetchWidgetConfigurations()
        return true
    }
    
    private func fetchWidgetConfigurations() {
        WidgetCenter.shared.getCurrentConfigurations { result in
            switch result {
            case .success(let configurations):
                print("Widget configurations loaded: \(configurations.count)")
            case .failure(let error):
                print("Failed to load widget configurations: \(error)")
            }
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        handleURL(url)
        return true
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
            if let listObjectIDString = shortcutItem.userInfo?["listId"] as? String,
               let url = URL(string: listObjectIDString),
               let objectID = PersistenceController.shared.persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) {
                NotificationCenter.default.post(name: .selectList, object: objectID)
            }
        default:
            break
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
