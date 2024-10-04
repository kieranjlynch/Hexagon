//
//  TagService.swift
//  Hexagon
//
//  Created by Kieran Lynch on 03/10/2024.
//

import Foundation
import CoreData
import Combine

@MainActor
public class TagService: ObservableObject {
    public static let shared = TagService()
    
    private let persistentContainer: NSPersistentContainer
    
    public init(persistenceController: PersistenceController = PersistenceController.shared) {
        self.persistentContainer = persistenceController.persistentContainer
    }
    
    public func fetchTags() async throws -> [Tag] {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
        
        return try await persistentContainer.viewContext.perform {
            do {
                return try self.persistentContainer.viewContext.fetch(request)
            } catch {
                throw error 
            }
        }
    }
    
    public func createTag(name: String) async throws -> Tag {
        let context = persistentContainer.viewContext
        return try await context.perform {
            let newTag = Tag(context: context)
            newTag.name = name
            newTag.tagID = UUID()
            try context.save()
            return newTag
        }
    }
}
