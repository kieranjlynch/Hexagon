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
public protocol SubHeadingManaging {
    func fetchSubHeadings(for taskList: TaskList) async throws -> [SubHeading]
    func saveSubHeading(title: String, taskList: TaskList) async throws -> SubHeading
    func updateSubHeading(_ subHeading: SubHeading, title: String) async throws
    func deleteSubHeading(_ subHeading: SubHeading) async throws
    func reorderSubHeadings(_ subHeadings: [SubHeading]) async throws
}

public protocol SubHeadingOperations {
    func addSubHeading(title: String, to taskList: TaskList) async throws
    func updateSubHeading(_ subHeading: SubHeading) async throws
    func deleteSubHeading(_ subHeading: SubHeading) async throws
    func reorderSubHeadings(_ subHeadings: [SubHeading]) async throws
    func moveSubHeadings(from source: IndexSet, to destination: Int, in taskList: TaskList) async throws
}

public protocol SubHeadingServiceFacade {
    func fetchSubHeadings(for list: TaskList) async throws -> [SubHeading]
    func fetchSubHeading(withID id: UUID) async throws -> SubHeading?
}

@MainActor
public class SubheadingService: ObservableObject, SubHeadingManaging, SubHeadingOperations, SubHeadingServiceFacade {
    public static let shared = SubheadingService(persistenceController: PersistenceController.shared)
    private let persistentContainer: NSPersistentContainer
    @Published public private(set) var subHeadings: [SubHeading] = []

    public init(persistenceController: PersistenceController) {
        self.persistentContainer = persistenceController.persistentContainer
    }

    public func fetchSubHeadings(for taskList: TaskList) async throws -> [SubHeading] {
        let context = persistentContainer.viewContext
        let taskListInContext = context.object(with: taskList.objectID) as! TaskList

        let request: NSFetchRequest<SubHeading> = SubHeading.fetchRequest()
        request.predicate = NSPredicate(format: "taskList == %@", taskListInContext)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SubHeading.order, ascending: true)]

        let results = try context.fetch(request)
        await MainActor.run {
            self.subHeadings = results
        }
        return results
    }

    public func saveSubHeading(title: String, taskList: TaskList) async throws -> SubHeading {
        let context = persistentContainer.viewContext

        let subHeading = SubHeading(context: context)
        subHeading.subheadingID = UUID()
        subHeading.title = title
        subHeading.order = Int16(try fetchMaxOrder(for: taskList) + 1)
        subHeading.taskList = taskList

        try context.save()

        await MainActor.run {
            NotificationCenter.default.post(name: .subheadingChanged, object: nil)
        }

        return subHeading
    }

    public func updateSubHeading(_ subHeading: SubHeading, title: String) async throws {
        let context = persistentContainer.viewContext

        subHeading.title = title

        try context.save()

        await MainActor.run {
            NotificationCenter.default.post(name: .subheadingChanged, object: nil)
        }
    }

    public func deleteSubHeading(_ subHeading: SubHeading) async throws {
        let context = persistentContainer.viewContext

        context.delete(subHeading)

        try context.save()

        await MainActor.run {
            NotificationCenter.default.post(name: .subheadingChanged, object: nil)
        }
    }

    public func reorderSubHeadings(_ subHeadings: [SubHeading]) async throws {
        let context = persistentContainer.viewContext

        for (index, subHeading) in subHeadings.enumerated() {
            subHeading.order = Int16(index)
        }

        try context.save()

        await MainActor.run {
            NotificationCenter.default.post(name: .subheadingChanged, object: nil)
        }
    }

    private func fetchMaxOrder(for taskList: TaskList) throws -> Int {
        let context = persistentContainer.viewContext

        let fetchRequest: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "SubHeading")
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.predicate = NSPredicate(format: "taskList == %@", taskList)

        let expression = NSExpressionDescription()
        expression.name = "maxOrder"
        expression.expression = NSExpression(forFunction: "max:", arguments: [NSExpression(forKeyPath: "order")])
        expression.expressionResultType = .integer32AttributeType
        fetchRequest.propertiesToFetch = [expression]

        if let result = try context.fetch(fetchRequest).first,
           let maxOrder = result["maxOrder"] as? Int {
            return maxOrder
        }
        return -1
    }

    public func moveReminder(_ reminder: Reminder, to subHeading: SubHeading?) async throws {
        let context = persistentContainer.viewContext

        let reminderInContext = context.object(with: reminder.objectID) as! Reminder
        reminderInContext.subHeading = subHeading

        try context.save()

        await MainActor.run {
            NotificationCenter.default.post(name: .subheadingChanged, object: nil)
        }
    }

    public func addSubHeading(title: String, to taskList: TaskList) async throws {
        _ = try await saveSubHeading(title: title, taskList: taskList)
    }

    public func updateSubHeading(_ subHeading: SubHeading) async throws {
        try await updateSubHeading(subHeading, title: subHeading.title ?? "")
    }
    
    public func fetchSubHeading(withID id: UUID) async throws -> SubHeading? {
            let context = PersistenceController.shared.persistentContainer.viewContext
            let request: NSFetchRequest<SubHeading> = SubHeading.fetchRequest()
            request.predicate = NSPredicate(format: "subheadingID == %@", id as CVarArg)
            request.fetchLimit = 1
            
            return try await context.perform {
                try request.execute().first
            }
        }

    public func moveSubHeadings(from source: IndexSet, to destination: Int, in taskList: TaskList) async throws {
        var subHeadings = try await fetchSubHeadings(for: taskList)
        subHeadings.move(fromOffsets: source, toOffset: destination)
        try await reorderSubHeadings(subHeadings)
    }

    public func deleteSubHeading(_ subHeading: SubHeading, in taskList: TaskList) async throws {
        try await deleteSubHeading(subHeading)
    }
}
