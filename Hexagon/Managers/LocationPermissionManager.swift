//  LocationPermissionManager.swift
//  Hexagon
//
//  Created by Kieran Lynch on 27/11/2024.
//

@preconcurrency import CoreLocation
import Combine


final class LocationPermissionManager: NSObject, CLLocationManagerDelegate, LocationPermissionsHandling, ObservableObject, @unchecked Sendable {
    static let shared = LocationPermissionManager()

    private let manager: CLLocationManager
    private let continuationQueue = DispatchQueue(label: "com.hexagon.locationmanager.continuation")
    private var _continuation: CheckedContinuation<Bool, Error>?

    private let authorizationStatusSubject = CurrentValueSubject<CLAuthorizationStatus, Never>(.notDetermined)

    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined {
        didSet {
            authorizationStatusSubject.send(authorizationStatus)
        }
    }

    private var continuation: CheckedContinuation<Bool, Error>? {
        get {
            continuationQueue.sync { _continuation }
        }
        set {
            continuationQueue.sync { _continuation = newValue }
        }
    }

    override private init() {
        self.manager = CLLocationManager()
        super.init()

        Task { @MainActor in
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyBest
            authorizationStatus = manager.authorizationStatus
        }
    }

    nonisolated func requestWhenInUseAuthorization() {
        Task { @MainActor in
            manager.requestWhenInUseAuthorization()
        }
    }

    nonisolated func requestLocationPermissions() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                self.continuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let newStatus = manager.authorizationStatus
            self.authorizationStatus = newStatus

            guard let continuation = continuation else { return }
            self.continuation = nil

            switch newStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                continuation.resume(returning: true)
            case .denied, .restricted:
                continuation.resume(returning: false)
            case .notDetermined:
                break
            @unknown default:
                continuation.resume(throwing: LocationError.unknownAuthorizationStatus)
            }
        }
    }
}
