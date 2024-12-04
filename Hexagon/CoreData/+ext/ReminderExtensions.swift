//  ReminderExtensions.swift
//  Hexagon
//
//  Created by Kieran Lynch on 17/09/2024.
//

import Foundation
import CoreData

extension Reminder {
    public var tagsArray: [ReminderTag] {
        let tagSet = tags as? Set<ReminderTag> ?? []
        return Array(tagSet).sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    public var photosArray: [ReminderPhoto] {
        let photoSet = photos as? Set<ReminderPhoto> ?? []
        return Array(photoSet)
    }
    
    public var notificationsArray: [String] {
        return notifications?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []
    }
}

extension Result {
    func mapError(_ transform: (Failure) -> Error) -> Result<Success, Error> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            return .failure(transform(error))
        }
    }
}

extension NSManagedObjectContext {
    func performAsync<T>(_ block: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            perform {
                do {
                    let result = try block()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
