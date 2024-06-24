import SwiftUI
import UserNotifications
import SharedDataFramework

@main
struct HexagonTaskManager: App {
    @StateObject private var permissionState = PermissionState()
    
    init() {
        requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, CoreDataProvider.shared.persistentContainer.viewContext)
                .environmentObject(permissionState)
                .onAppear {
                    checkPermissions()
                }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    private func checkPermissions() {
        permissionState.locationPermissionGranted = PermissionManager.shared.checkLocationPermission()
        permissionState.calendarPermissionGranted = PermissionManager.shared.checkCalendarPermission()
        permissionState.photoLibraryPermissionGranted = PermissionManager.shared.checkPhotoLibraryPermission()
    }
}

class PermissionState: ObservableObject {
    @Published var locationPermissionGranted = false
    @Published var calendarPermissionGranted = false
    @Published var photoLibraryPermissionGranted = false
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(locationPermissionChanged(_:)), name: .locationPermissionChanged, object: nil)
    }
    
    @objc func locationPermissionChanged(_ notification: Notification) {
        if let granted = notification.userInfo?["granted"] as? Bool {
            DispatchQueue.main.async {
                self.locationPermissionGranted = granted
            }
        }
    }
    
    func requestLocationPermissionIfNeeded() {
        guard !locationPermissionGranted else { return }
        PermissionManager.shared.requestLocationPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.locationPermissionGranted = granted
            }
        }
    }
    
    func requestCalendarPermissionIfNeeded() {
        guard !calendarPermissionGranted else { return }
        PermissionManager.shared.requestCalendarPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.calendarPermissionGranted = granted
            }
        }
    }
    
    func requestPhotoLibraryPermissionIfNeeded() {
        guard !photoLibraryPermissionGranted else { return }
        PermissionManager.shared.requestPhotoLibraryPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.photoLibraryPermissionGranted = granted
            }
        }
    }
}
