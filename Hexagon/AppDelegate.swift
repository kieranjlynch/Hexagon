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
        printWidgetConfigurations()
        return true
    }
    
    private func printWidgetConfigurations() {
        WidgetCenter.shared.getCurrentConfigurations { result in
            switch result {
            case .success(let widgetInfos):
                for widgetInfo in widgetInfos {
                    print("Widget Kind: \(widgetInfo.kind)")
                    print("Widget Family: \(widgetInfo.family)")
                    if let configuration = widgetInfo.configuration {
                        print("Configuration: \(configuration)")
                    }
                }
            case .failure(let error):
                print("Error fetching widget configurations: \(error)")
            }
        }
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        DateFormatter.updateSharedDateFormatter()
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        DateFormatter.updateSharedDateFormatter()
    }
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        NotificationCenter.default.post(name: .handleQuickAction, object: shortcutItem)
        completionHandler(true)
    }
}

extension Notification.Name {
    static let handleQuickAction = Notification.Name("HandleQuickAction")
}
