//
//  PhotoService.swift
//  Hexagon
//
//  Created by Kieran Lynch on 03/10/2024.
//

import Foundation
import CoreData
import UIKit

@MainActor
public class PhotoService {
    public static let shared = PhotoService()
    private let persistentContainer: NSPersistentContainer
    private let fileManager = FileManager.default
    private let photosDirectory: URL
    
    public init(persistenceController: PersistenceController = PersistenceController.shared) {
        self.persistentContainer = persistenceController.persistentContainer
        
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.photosDirectory = documentsPath.appendingPathComponent("ReminderPhotos")
        
        try? fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
    }
    
    public func setReminderPhotos(reminderToSave: Reminder, photos: [UIImage], context: NSManagedObjectContext) async throws {
        try await context.perform { [weak self] in
            guard let self = self else { return }

            if let existingPhotos = reminderToSave.photos {
                for case let photo as ReminderPhoto in existingPhotos {
                    if let filename = photo.photoData?.base64EncodedString() {
                        let fileURL = self.photosDirectory.appendingPathComponent(filename)
                        try? self.fileManager.removeItem(at: fileURL)
                    }
                    context.delete(photo)
                }
                reminderToSave.photos = nil
            }
            
            let reminderPhotos = try photos.enumerated().map { index, photo -> ReminderPhoto in
                let reminderPhoto = ReminderPhoto(context: context)
                let filename = UUID().uuidString + ".jpg"
                let fileURL = self.photosDirectory.appendingPathComponent(filename)
                
                guard let imageData = photo.jpegData(compressionQuality: 0.8) else {
                    throw PhotoError.compressionFailed
                }
                
                try imageData.write(to: fileURL)
                reminderPhoto.photoData = filename.data(using: .utf8)
                reminderPhoto.order = Int16(index)
                reminderPhoto.reminder = reminderToSave
                return reminderPhoto
            }

            reminderToSave.photos = NSSet(array: reminderPhotos)
        }
    }
    
    public func getPhotos(for reminder: Reminder) -> [UIImage] {
        guard let photos = reminder.photos as? Set<ReminderPhoto> else {
            return []
        }
        
        return photos.compactMap { photo in
            guard let filename = photo.photoData?.base64EncodedString() else { return nil }
            let fileURL = photosDirectory.appendingPathComponent(filename)
            guard let data = try? Data(contentsOf: fileURL) else { return nil }
            return UIImage(data: data)
        }
    }
    
    public func clearOrphanedPhotos() async throws {
        let context = persistentContainer.newBackgroundContext()
        try await context.perform { [weak self] in
            guard let self = self else { return }
            
            let request: NSFetchRequest<ReminderPhoto> = ReminderPhoto.fetchRequest()
            let savedPhotos = try context.fetch(request)
            let savedFilenames = Set(savedPhotos.compactMap { $0.photoData?.base64EncodedString() })
            
            let fileURLs = try self.fileManager.contentsOfDirectory(at: self.photosDirectory,
                                                                   includingPropertiesForKeys: nil)
            
            for fileURL in fileURLs {
                let filename = fileURL.lastPathComponent
                if !savedFilenames.contains(filename) {
                    try self.fileManager.removeItem(at: fileURL)
                }
            }
        }
    }
    
    public func deleteAllPhotos() async throws {
        let context = persistentContainer.newBackgroundContext()
        try await context.perform { [weak self] in
            guard let self = self else { return }
            
            let request: NSFetchRequest<ReminderPhoto> = ReminderPhoto.fetchRequest()
            let allPhotos = try context.fetch(request)
            
            for photo in allPhotos {
                if let filename = photo.photoData?.base64EncodedString() {
                    let fileURL = self.photosDirectory.appendingPathComponent(filename)
                    try? self.fileManager.removeItem(at: fileURL)
                }
                context.delete(photo)
            }
            
            try context.save()

            let fileURLs = try self.fileManager.contentsOfDirectory(at: self.photosDirectory,
                                                                   includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try self.fileManager.removeItem(at: fileURL)
            }
        }
    }
    
    enum PhotoError: LocalizedError {
        case compressionFailed
        
        var errorDescription: String? {
            switch self {
            case .compressionFailed:
                return "Failed to compress image data"
            }
        }
    }
}
