//
//  SubheadingService.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import Foundation
import CoreData
import Combine

@MainActor
public class SubheadingService: ObservableObject {
    private let context: NSManagedObjectContext
    
    @Published public private(set) var subHeadings: [SubHeading] = []
    
    public init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    public func saveSubHeading(title: String, taskList: TaskList) async throws -> SubHeading {
        try await context.perform {
            let subHeading = SubHeading(context: self.context)
            subHeading.subheadingID = UUID()
            subHeading.title = title
            subHeading.order = Int16(taskList.subHeadings?.count ?? 0)
            subHeading.taskList = taskList
            taskList.addToSubHeadings(subHeading)
            
            try self.context.save()
            
            return subHeading
        }
    }
    
    public func fetchSubHeadings(for taskList: TaskList) async throws -> [SubHeading] {
        let request: NSFetchRequest<SubHeading> = SubHeading.fetchRequest()
        request.predicate = NSPredicate(format: "taskList == %@", taskList)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SubHeading.order, ascending: true)]
        
        return try await context.perform {
            let results = try self.context.fetch(request)
            print("Fetched \(results.count) subheadings for task list \(taskList.name ?? "Unnamed List")")
            results.forEach { subHeading in
                print("Subheading: \(subHeading.title ?? "Unnamed")")
            }
            return results
        }
    }
    
    public func fetchSubHeadingsCount(for taskList: TaskList) async throws -> Int {
        try await context.perform {
            let request: NSFetchRequest<SubHeading> = SubHeading.fetchRequest()
            request.predicate = NSPredicate(format: "taskList == %@", taskList)
            return try self.context.count(for: request)
        }
    }
    
    public func updateSubHeading(_ subHeading: SubHeading, title: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.context.perform {
                do {
                    subHeading.title = title
                    try self.context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        if let taskList = subHeading.taskList {
            _ = try await fetchSubHeadings(for: taskList)
        }
    }
    
    public func deleteSubHeading(_ subHeading: SubHeading) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.context.perform {
                do {
                    self.context.delete(subHeading)
                    try self.context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        if let taskList = subHeading.taskList {
            _ = try await fetchSubHeadings(for: taskList)
        }
    }
    
    public func reorderSubHeadings(_ subHeadings: [SubHeading]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.context.perform {
                do {
                    for (index, subHeading) in subHeadings.enumerated() {
                        subHeading.order = Int16(index)
                    }
                    try self.context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        if let taskList = subHeadings.first?.taskList {
            _ = try await fetchSubHeadings(for: taskList)
        }
    }
    
    public func moveReminder(_ reminder: Reminder, to subHeading: SubHeading?) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.context.perform {
                do {
                    reminder.subHeading = subHeading
                    try self.context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        if let taskList = subHeading?.taskList {
            _ = try await fetchSubHeadings(for: taskList)
        }
    }
}
