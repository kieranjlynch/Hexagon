//
//  SubheadingManager.swift
//  Hexagon
//
//  Created by Kieran Lynch on 14/11/2024.
//

import Foundation
import CoreData


final class SubheadingManager: SubHeadingManaging {
    static let shared = SubheadingManager()
    private let persistentContainer: NSPersistentContainer
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistentContainer = persistenceController.persistentContainer
    }
    
    func fetchSubHeadings(for taskList: TaskList) async throws -> [SubHeading] {
        let context = persistentContainer.viewContext
        let request = NSFetchRequest<SubHeading>(entityName: "SubHeading")
        request.predicate = NSPredicate(format: "taskList == %@", taskList)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SubHeading.order, ascending: true)]
        return try context.fetch(request)
    }
    
    func saveSubHeading(title: String, taskList: TaskList) async throws -> SubHeading {
        let context = persistentContainer.viewContext
        let subHeading = SubHeading(context: context)
        subHeading.title = title
        subHeading.taskList = taskList
        subHeading.order = Int16(try await fetchSubHeadings(for: taskList).count)
        try context.save()
        return subHeading
    }
    
    func updateSubHeading(_ subHeading: SubHeading, title: String) async throws {
        let context = persistentContainer.viewContext
        subHeading.title = title
        try context.save()
    }
    
    func deleteSubHeading(_ subHeading: SubHeading) async throws {
        let context = persistentContainer.viewContext
        context.delete(subHeading)
        try context.save()
    }
    
    func reorderSubHeadings(_ subHeadings: [SubHeading]) async throws {
        let context = persistentContainer.viewContext
        for (index, subHeading) in subHeadings.enumerated() {
            subHeading.order = Int16(index)
        }
        try context.save()
    }
}
