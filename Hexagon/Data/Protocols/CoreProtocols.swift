//
//  CoreProtocols.swift
//  Hexagon
//
//  Created by Kieran Lynch on 03/12/2024.
//

import SwiftUI
import Combine
import EventKit
import os
import MapKit

public protocol AsyncDataProvider {
    func performLoad() async
    func refreshData() async
}

public protocol StateManaging {
    associatedtype State: Equatable
    var state: ViewState<State> { get async }  
    nonisolated func updateViewState(_ newState: ViewState<State>) async
}

public protocol DataLoadable {
    associatedtype LoadedData
    func loadContent() async throws -> LoadedData
    func handleLoadedContent(_ content: LoadedData)
}

protocol ViewModelProtocol: StateManaging {
    associatedtype LoadedData
    
    func initialize() async
    func cleanup() async
    func handleLoadedContent(_ content: LoadedData) async
    func handleLoadError(_ error: Error) async
}

public protocol ListDataManaging {
    func moveItem(_ item: ListItemTransfer, toIndex: Int)
    func reorderItems(from: IndexSet, to: Int)
    func deleteItem(_ item: ListItemTransfer) async throws
}

public protocol SearchDataManaging {
    func performSearch(query: String) async throws
    func clearSearch()
}

public protocol TaskListManaging {
    func fetchTaskLists() async throws -> [TaskList]
    func fetchRecentLists(limit: Int) async throws -> [TaskList]
    func deleteTaskList(_ taskList: TaskList) async throws
    func updateTaskList(_ taskList: TaskList) async throws
    func createTaskList(name: String, color: UIColor, symbol: String) async throws -> TaskList
}

public protocol CalendarManaging {
    func fetchEvents(from: Date, to: Date) async throws -> [EKEvent]
    func requestAccess() async throws -> Bool
    func saveEvent(title: String, startDate: Date, endDate: Date) async throws
}

public protocol LocationManaging {
    func fetchLocations() async throws -> [LocationModel]
    func saveLocation(_ name: String, coordinate: CLLocationCoordinate2D) async throws
}

public protocol ViewStateManaging {
    associatedtype State: Equatable
    var state: ViewState<State> { get }
    func updateViewState(_ newState: ViewState<State>) async
}

public protocol ErrorHandlingViewModel: AnyObject {
    var errorHandler: ErrorHandling { get }
    var logger: Logger { get }
}

extension ErrorHandlingViewModel {
    @MainActor
    func handleError(_ error: Error) {
        Task { @MainActor in
            errorHandler.handle(error, logger: logger)
        }
    }
}

public protocol BaseProvider {
    associatedtype T
    func fetch() async throws -> [T]
    func fetchOne(id: UUID) async throws -> T?
    func save(_ item: T) async throws
    func delete(_ item: T) async throws
}

@MainActor
public protocol TaskManaging: AnyObject {
    var activeTasks: Set<Task<Void, Never>> { get set }
    var cancellables: Set<AnyCancellable> { get set }
}

public protocol LoggerProvider: AnyObject {
    var logger: Logger { get }
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
