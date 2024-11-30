//
//  Protocols.swift
//  Hexagon
//
//  Created by Kieran Lynch on 13/11/2024.
//

import Foundation
import CoreData
import UIKit
import MapKit
import EventKit
import os
import Combine

public protocol BaseProvider {
    associatedtype T
    func fetch() async throws -> [T]
    func fetchOne(id: UUID) async throws -> T?
    func save(_ item: T) async throws
    func delete(_ item: T) async throws
}

@MainActor
public protocol StateManaging: ObservableObject {
    associatedtype State: Equatable
    var state: ViewState<State> { get set }
    func updateViewState(_ newState: ViewState<State>)
}

@MainActor
public protocol ErrorHandling: ObservableObject {
    var error: IdentifiableError? { get set }
    func handleError(_ error: Error)
}

@MainActor
public protocol TaskManaging: AnyObject {
    var activeTasks: Set<Task<Void, Never>> { get set }
    var cancellables: Set<AnyCancellable> { get set }
}

public protocol LoggerProvider: AnyObject {
    var logger: Logger { get }
}

@MainActor
public protocol ViewStateManaging: StateManaging where State: Equatable {
    var viewState: State { get }
    var state: ViewState<State> { get set }
    func updateViewState(_ newState: ViewState<State>)
}

public protocol TagServiceProtocol {
    func createTag(name: String) async throws -> ReminderTag
}

@MainActor
public protocol ReminderDetailsPresenting {
    var reminder: Reminder { get }
    var tags: [String] { get }
    var notifications: [String] { get }
    var photos: [ReminderPhoto] { get }
    var isPlaying: Bool { get }
    var hasDates: Bool { get }
    var hasURL: Bool { get }
    var hasVoiceNote: Bool { get }
    var priorityText: String { get }
}

public protocol LocationSearchFacade {
    var searchResults: [MKMapItem] { get async }
    func searchLocations(query: String, in region: MKCoordinateRegion) async throws -> [MKMapItem]
}

public protocol LocationPermissionsHandling {
    var authorizationStatus: CLAuthorizationStatus { get }
    func requestWhenInUseAuthorization()
    func requestLocationPermissions() async throws -> Bool
}



protocol LocationPermissionsFacade: Sendable {
    var authorizationStatus: CLAuthorizationStatus { get }
    func requestWhenInUseAuthorization()
    func requestLocationPermissions() async throws -> Bool
}

public protocol TaskGrouping {
    func groupTasksByDate(_ tasks: [Reminder]) -> [Date: [Reminder]]
}

@MainActor
public protocol CacheManaging {
    func preloadContent(for indices: [Int])
    func cleanupContent(for index: Int)
    func cleanupMemory()
}

@MainActor
public protocol AudioPlaybackManaging {
    var isPlaying: Bool { get }
    func startPlayback(data: Data) throws
    func stopPlayback()
    func pausePlayback()
}

@MainActor
public protocol ViewModel: ObservableObject {
    associatedtype State: Equatable
    var viewState: State { get }
    var error: IdentifiableError? { get set }
    var activeTasks: Set<Task<Void, Never>> { get set }
    var cancellables: Set<AnyCancellable> { get set }
}

public protocol ReminderOperations {
    func moveReminders(from source: IndexSet, to destination: Int, in subHeading: SubHeading) async throws
}

public enum ReminderSortType {
    case priorityAscending
    case priorityDescending
    case dueDateAscending
    case dueDateDescending

    public var sortDescriptorRepresentation: SortDescriptorRepresentation {
        switch self {
        case .priorityAscending:
            return SortDescriptorRepresentation(key: "priority", ascending: true)
        case .priorityDescending:
            return SortDescriptorRepresentation(key: "priority", ascending: false)
        case .dueDateAscending:
            return SortDescriptorRepresentation(key: "startDate", ascending: true)
        case .dueDateDescending:
            return SortDescriptorRepresentation(key: "startDate", ascending: false)
        }
    }
}
