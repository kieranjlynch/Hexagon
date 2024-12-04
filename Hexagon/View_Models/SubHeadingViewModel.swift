//
//  SubHeadingViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 04/11/2024.
//

import SwiftUI
import CoreData
import Foundation
import Combine
import os

extension SubHeading {
    public static func == (lhs: SubHeading, rhs: SubHeading) -> Bool {
        return lhs.objectID == rhs.objectID
    }
}

@MainActor
final class SubHeadingViewModel: ObservableObject, ViewModel, ErrorHandling, TaskManaging, LoggerProvider {
    typealias State = [SubHeading]
    
    @Published private(set) var subHeadings: [SubHeading] = []
    @Published var state: ViewState<[SubHeading]> = .idle
    @Published var error: IdentifiableError?
    
    var activeTasks = Set<Task<Void, Never>>()
    var cancellables = Set<AnyCancellable>()
    
    let logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "SubHeadingViewModel")
    
    @Published private(set) var currentTaskList: TaskList?
    
    var viewState: [SubHeading] {
        subHeadings
    }
    
    private let subheadingManager: SubHeadingManaging
    private let performanceMonitor: PerformanceMonitoring
    private var isInitialized = false
    private weak var parentViewModel: SubHeadingViewModel?
    
    init(
        subheadingManager: SubHeadingManaging,
        performanceMonitor: PerformanceMonitoring,
        parentViewModel: SubHeadingViewModel? = nil
    ) {
        self.subheadingManager = subheadingManager
        self.performanceMonitor = performanceMonitor
        self.parentViewModel = parentViewModel
        
        if parentViewModel == nil {
            setupObservers()
        }
    }
    
    func updateViewState(_ newState: ViewState<[SubHeading]>) {
        state = newState
        if case .error(let message) = newState {
            handleError(BaseAppError(errorCode: -1, category: .ui, description: message))
        }
    }
    
    @MainActor
    func handle(_ error: Error) {
        handle(error, logger: nil)
    }
    
    @MainActor
    func handle(_ error: Error, logger: Logger?) {
        ErrorHandlerService.shared.handle(error, logger: logger ?? self.logger)
        self.error = IdentifiableError(error: error)
    }
    
    func viewDidLoad() {
        // Implement any setup needed when the view loads
    }
    
    func viewWillAppear() {
        // Implement any actions needed when the view appears
    }
    
    func viewWillDisappear() {
        // Implement any cleanup needed when the view disappears
    }
    
    func handleError(_ error: Error) {
        self.error = IdentifiableError(error: error)
    }
    
    func fetchSubHeadings(for taskList: TaskList) async throws {
        if let parent = parentViewModel {
            self.subHeadings = parent.subHeadings
            self.currentTaskList = parent.currentTaskList
            return
        }
        
        guard !isInitialized || self.currentTaskList?.objectID != taskList.objectID else { return }
        
        await performanceMonitor.startOperation("fetchSubHeadings")
        updateViewState(.loading)
        
        do {
            let fetchedHeadings = try await subheadingManager.fetchSubHeadings(for: taskList)
            await MainActor.run {
                self.subHeadings = fetchedHeadings
                self.currentTaskList = taskList
                self.isInitialized = true
                self.updateViewState(.loaded(fetchedHeadings))
            }
        } catch {
            await MainActor.run {
                self.updateViewState(.error(error.localizedDescription))
            }
            logger.error("Failed to fetch subheadings: \(error.localizedDescription)")
            handleError(error)
            throw error
        }
        
        await performanceMonitor.endOperation("fetchSubHeadings")
    }
    
    func addSubHeading(title: String, to taskList: TaskList) async throws {
        if let parent = parentViewModel {
            try await parent.addSubHeading(title: title, to: taskList)
            self.subHeadings = parent.subHeadings
            return
        }
        
        await performanceMonitor.startOperation("addSubHeading")
        
        do {
            let newSubHeading = try await subheadingManager.saveSubHeading(title: title, taskList: taskList)
            await MainActor.run {
                self.subHeadings.append(newSubHeading)
                self.updateViewState(.loaded(self.subHeadings))
            }
            
            try await self.fetchSubHeadings(for: taskList)
            NotificationCenter.default.post(name: .NSManagedObjectContextObjectsDidChange, object: nil)
        } catch {
            logger.error("Error adding subheading: \(error.localizedDescription)")
            handleError(error)
            throw error
        }
        
        await performanceMonitor.endOperation("addSubHeading")
    }
    
    func updateSubHeading(_ subHeading: SubHeading, title: String) async throws {
        if let parent = parentViewModel {
            try await parent.updateSubHeading(subHeading, title: title)
            self.subHeadings = parent.subHeadings
            return
        }
        
        await performanceMonitor.startOperation("updateSubHeading")
        
        do {
            try await subheadingManager.updateSubHeading(subHeading, title: title)
            
            if let index = subHeadings.firstIndex(where: { $0.objectID == subHeading.objectID }) {
                await MainActor.run {
                    let updatedSubHeading = subHeading
                    updatedSubHeading.title = title
                    self.subHeadings[index] = updatedSubHeading
                    self.updateViewState(.loaded(self.subHeadings))
                }
            }
            
            if let taskList = subHeading.taskList {
                try await self.fetchSubHeadings(for: taskList)
            }
            
            NotificationCenter.default.post(name: .NSManagedObjectContextObjectsDidChange, object: nil)
        } catch {
            logger.error("Error updating subheading: \(error.localizedDescription)")
            handleError(error)
            throw error
        }
        
        await performanceMonitor.endOperation("updateSubHeading")
    }
    
    func deleteSubHeading(_ subHeading: SubHeading) async throws {
        if let parent = parentViewModel {
            try await parent.deleteSubHeading(subHeading)
            self.subHeadings = parent.subHeadings
            return
        }
        
        await performanceMonitor.startOperation("deleteSubHeading")
        
        do {
            try await subheadingManager.deleteSubHeading(subHeading)
            
            await MainActor.run {
                subHeadings.removeAll { $0.objectID == subHeading.objectID }
                self.updateViewState(.loaded(self.subHeadings))
            }
            
            if let taskList = subHeading.taskList {
                try await self.fetchSubHeadings(for: taskList)
            }
            
            NotificationCenter.default.post(name: .NSManagedObjectContextObjectsDidChange, object: nil)
        } catch {
            logger.error("Error deleting subheading: \(error.localizedDescription)")
            handleError(error)
            throw error
        }
        
        await performanceMonitor.endOperation("deleteSubHeading")
    }
    
    func reorderSubHeadings(from source: IndexSet, to destination: Int) async throws {
        if let parent = parentViewModel {
            try await parent.reorderSubHeadings(from: source, to: destination)
            self.subHeadings = parent.subHeadings
            return
        }
        
        await performanceMonitor.startOperation("reorderSubHeadings")
        
        var updatedSubHeadings = subHeadings
        updatedSubHeadings.move(fromOffsets: source, toOffset: destination)
        
        for (index, subHeading) in updatedSubHeadings.enumerated() {
            subHeading.order = Int16(index)
        }
        
        do {
            try await subheadingManager.reorderSubHeadings(updatedSubHeadings)
            await MainActor.run {
                self.subHeadings = updatedSubHeadings
                self.updateViewState(.loaded(self.subHeadings))
            }
            
            if let taskList = updatedSubHeadings.first?.taskList {
                try await self.fetchSubHeadings(for: taskList)
            }
            
            NotificationCenter.default.post(name: .NSManagedObjectContextObjectsDidChange, object: nil)
        } catch {
            logger.error("Error reordering subheadings: \(error.localizedDescription)")
            handleError(error)
            throw error
        }
        
        await performanceMonitor.endOperation("reorderSubHeadings")
    }
    
    func moveSubHeading(_ subHeading: SubHeading, to index: Int) async throws {
        if let parent = parentViewModel {
            try await parent.moveSubHeading(subHeading, to: index)
            self.subHeadings = parent.subHeadings
            return
        }
        
        await performanceMonitor.startOperation("moveSubHeading")
        
        guard validateMove(of: subHeading, to: index) else {
            logger.debug("Invalid move attempt for subheading: \(subHeading.title ?? "unknown")")
            return
        }
        
        var currentSubHeadings = subHeadings
        if let currentIndex = currentSubHeadings.firstIndex(of: subHeading) {
            currentSubHeadings.remove(at: currentIndex)
            currentSubHeadings.insert(subHeading, at: index)
            
            for (i, heading) in currentSubHeadings.enumerated() {
                heading.order = Int16(i)
            }
            
            do {
                try await subheadingManager.reorderSubHeadings(currentSubHeadings)
                await MainActor.run {
                    self.subHeadings = currentSubHeadings
                    self.updateViewState(.loaded(self.subHeadings))
                }
                
                if let taskList = subHeading.taskList {
                    try await self.fetchSubHeadings(for: taskList)
                }
                
                NotificationCenter.default.post(name: .NSManagedObjectContextObjectsDidChange, object: nil)
            } catch {
                logger.error("Error moving subheading: \(error.localizedDescription)")
                handleError(error)
                throw error
            }
        }
        
        await performanceMonitor.endOperation("moveSubHeading")
    }
    
    func validateMove(of subHeading: SubHeading, to index: Int) -> Bool {
        if let parent = parentViewModel {
            return parent.validateMove(of: subHeading, to: index)
        }
        let currentOrder = Int(subHeading.order)
        return currentOrder != index && index >= 0 && index < subHeadings.count
    }
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    if let taskList = self.currentTaskList {
                        try? await self.fetchSubHeadings(for: taskList)
                    }
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    if let taskList = self.currentTaskList {
                        try? await self.fetchSubHeadings(for: taskList)
                    }
                }
            }
            .store(in: &cancellables)
    }
}
