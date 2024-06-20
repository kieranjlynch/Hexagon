import Foundation
import CoreData
import UIKit
import CoreLocation

enum ReminderStatType {
    case today
    case scheduled
    case all
    case completed
    case withNotes
    case withURL
    case withPriority
    case withTag
    case overdue
    case withLocation
}

class ReminderService {
    
    static func getReminderById(id: UUID) throws -> Reminder? {
        let context = CoreDataProvider.shared.persistentContainer.viewContext
        let request = Reminder.fetchRequest()
        request.predicate = NSPredicate(format: "identifier == %@", id as CVarArg)
        
        return try context.fetch(request).first
    }
    
    static func getUnassignedAndIncompleteReminders() -> NSFetchRequest<Reminder> {
        let request = Reminder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.title, ascending: true)]
        request.predicate = NSPredicate(format: "list = nil AND isCompleted = false")
        return request
    }
    
    static func saveReminder(reminder: Reminder, location: CLLocationCoordinate2D, radius: Double) throws {
        let context = CoreDataProvider.shared.persistentContainer.viewContext
        
        let locationEntity = Location(context: context)
        locationEntity.latitude = location.latitude
        locationEntity.longitude = location.longitude
        locationEntity.name = "Reminder Location"
        reminder.location = locationEntity
        reminder.radius = radius
        reminder.identifier = UUID()
        
        try save()
        LocationService.shared.startMonitoringLocation(for: reminder)
    }
    
    static var viewContext: NSManagedObjectContext {
        CoreDataProvider.shared.persistentContainer.viewContext
    }
    
    static func save() throws {
        try viewContext.save()
    }
    
    static func saveTaskList(_ name: String, _ color: UIColor, _ symbol: String) throws {
        let taskList = TaskList(context: viewContext)
        taskList.name = name
        taskList.color = color
        taskList.symbol = symbol
        try save()
    }
    
    static func getAvailableTasks() -> NSFetchRequest<Reminder> {
        let request = Reminder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.title, ascending: true)]
        let now = Date()
        request.predicate = NSPredicate(format: "startDate <= %@ AND isCompleted = false", now as NSDate)
        return request
    }
    
    static func updateReminder(reminder: Reminder, editConfig: ReminderEditConfig) throws -> Bool {
        let reminderToUpdate = reminder
        reminderToUpdate.isCompleted = editConfig.isCompleted
        reminderToUpdate.title = editConfig.title
        reminderToUpdate.notes = editConfig.notes
        reminderToUpdate.endDate = editConfig.hasDate ? editConfig.endDate : nil
        reminderToUpdate.reminderTime = editConfig.hasTime ? editConfig.reminderTime : nil
        reminderToUpdate.startDate = editConfig.startDate
        reminderToUpdate.endDate = editConfig.endDate
        reminderToUpdate.priority = Int16(editConfig.priority)
        reminderToUpdate.tag = editConfig.tag
        reminderToUpdate.url = editConfig.url
        
        if let existingPhotos = reminderToUpdate.photos as? Set<NSManagedObject> {
            existingPhotos.forEach { viewContext.delete($0) }
        }
        
        editConfig.photos.forEach { photo in
            let reminderPhoto = ReminderPhoto(context: viewContext)
            reminderPhoto.photoData = photo.pngData()
            reminderToUpdate.addToPhotos(reminderPhoto)
        }
        
        try save()
        return true
    }
    
    static func deleteReminder(_ reminder: Reminder) throws {
        viewContext.delete(reminder)
        try save()
    }
    
    static func saveReminderToMyList(myList: TaskList, reminderTitle: String, startDate: Date, endDate: Date, priority: Int, tag: String, url: String, notes: String) throws {
        let reminder = Reminder(context: viewContext)
        reminder.title = reminderTitle
        reminder.startDate = startDate
        reminder.endDate = endDate
        reminder.priority = Int16(priority)
        reminder.tag = tag
        reminder.url = url
        reminder.notes = notes
        myList.addToReminders(reminder)
        try save()
    }
    
    static func getRemindersBySearchTerm(_ searchTerm: String) -> NSFetchRequest<Reminder> {
        let request = Reminder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.title, ascending: true)]
        request.predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchTerm)
        return request
    }
    
    static func saveReminderToMyList(myList: TaskList, reminderTitle: String) throws {
        let reminder = Reminder(context: viewContext)
        reminder.title = reminderTitle
        myList.addToReminders(reminder)
        try save()
    }
    
    static func remindersByStatType(statType: ReminderStatType) -> NSFetchRequest<Reminder> {
        let request = Reminder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.title, ascending: true)]
        
        switch statType {
        case .all:
            request.predicate = NSPredicate(format: "isCompleted = false")
        case .today:
            let today = Date()
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)
            request.predicate = NSPredicate(format: "(endDate >= %@) AND (endDate < %@)", today as NSDate, tomorrow! as NSDate)
        case .scheduled:
            request.predicate = NSPredicate(format: "(endDate != nil OR reminderTime != nil) AND isCompleted = false")
        case .completed:
            request.predicate = NSPredicate(format: "isCompleted = true")
        case .withNotes:
            request.predicate = NSPredicate(format: "notes != nil AND notes != ''")
        case .withURL:
            request.predicate = NSPredicate(format: "url != nil AND url != ''")
        case .withPriority:
            request.predicate = NSPredicate(format: "priority > 0")
        case .withTag:
            request.predicate = NSPredicate(format: "tag != nil AND tag != ''")
        case .overdue:
            let now = Date()
            request.predicate = NSPredicate(format: "(endDate < %@ OR reminderTime < %@) AND isCompleted = false", now as NSDate, now as NSDate)
        case .withLocation:
            request.predicate = NSPredicate(format: "location != nil")
        }
        
        return request
    }
    
    static func getUnassignedReminders() -> NSFetchRequest<Reminder> {
        let request = Reminder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.title, ascending: true)]
        request.predicate = NSPredicate(format: "list = nil")
        return request
    }
    
    static func saveTag(_ name: String) throws {
        let tag = Tag(context: viewContext)
        tag.name = name
        try save()
    }
    
    static func deleteTag(_ tag: Tag) throws {
        viewContext.delete(tag)
        try save()
    }
    
    static func getRemindersByList(myList: TaskList) -> NSFetchRequest<Reminder> {
        let request = Reminder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.title, ascending: true)]
        request.predicate = NSPredicate(format: "list = %@", myList)
        return request
    }
}
