//  AppIntents.swift
//  Hexagon
//
//  Created by Kieran Lynch on 25/11/2024.
//

import AppIntents
import CoreData
import Foundation


enum TaskError: Error {
    case taskNotFound
    case invalidInput
    
    var localizedDescription: String {
        switch self {
        case .taskNotFound: return "Task not found"
        case .invalidInput: return "Invalid input"
        }
    }
}

struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task"
    static var description: LocalizedStringResource = "Create a new task in Hexagon"

    @Parameter(title: "Title")
    var title: String
    
    @Parameter(title: "Notes")
    var notes: String?
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Add Task: \(title)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = PersistenceController.shared.persistentContainer.viewContext
        let reminder = Reminder(context: context)
        reminder.title = title
        reminder.notes = notes
        reminder.reminderID = UUID()
        reminder.isInInbox = true
        try context.save()
        return .result(dialog: "Task added: \(title)")
    }
}

struct DeleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Delete Task"
    static var description: LocalizedStringResource = "Delete an existing task"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Delete Task")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            context.delete(reminder)
            try context.save()
            return .result(dialog: "Task deleted")
        }
        throw TaskError.taskNotFound
    }
}

struct GetTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Task"
    static var description: LocalizedStringResource = "Retrieve details of a specific task"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Get Task")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            return .result(dialog: "Task: \(reminder.title ?? "Untitled")")
        }
        throw TaskError.taskNotFound
    }
}

struct AddNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Note"
    static var description: LocalizedStringResource = "Add a note to an existing task"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    @Parameter(title: "Note")
    var note: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Add Note")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            reminder.notes = note
            try context.save()
            return .result(dialog: "Note added")
        }
        throw TaskError.taskNotFound
    }
}

struct UpdateNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Update Note"
    static var description: LocalizedStringResource = "Update the note of an existing task"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    @Parameter(title: "Note")
    var note: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Update Note")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            reminder.notes = note
            try context.save()
            return .result(dialog: "Note updated")
        }
        throw TaskError.taskNotFound
    }
}

struct DeleteNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Delete Note"
    static var description: LocalizedStringResource = "Remove a note from a task"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Delete Note")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            reminder.notes = nil
            try context.save()
            return .result(dialog: "Note deleted")
        }
        throw TaskError.taskNotFound
    }
}

struct AddTagIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Tag"
    static var description: LocalizedStringResource = "Add a tag to a task"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    @Parameter(title: "Tag Name")
    var tagName: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Add Tag: \(tagName)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            let tag = ReminderTag(context: context)
            tag.name = tagName
            tag.tagID = UUID()
            tag.addToReminders(reminder)
            try context.save()
            return .result(dialog: "Tag added: \(tagName)")
        }
        throw TaskError.taskNotFound
    }
}

struct UpdateTagIntent: AppIntent {
    static var title: LocalizedStringResource = "Update Tag"
    static var description: LocalizedStringResource = "Update an existing tag"
    
    @Parameter(title: "Tag ID")
    var tagID: String
    
    @Parameter(title: "New Tag Name")
    var newTagName: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Update Tag: \(newTagName)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: tagID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<ReminderTag> = ReminderTag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "tagID == %@", uuid as CVarArg)
        
        if let tag = try context.fetch(fetchRequest).first {
            tag.name = newTagName
            try context.save()
            return .result(dialog: "Tag updated to: \(newTagName)")
        }
        throw TaskError.taskNotFound
    }
}

struct DeleteTagIntent: AppIntent {
    static var title: LocalizedStringResource = "Delete Tag"
    static var description: LocalizedStringResource = "Remove a tag from a task"
    
    @Parameter(title: "Tag ID")
    var tagID: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Delete Tag")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: tagID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<ReminderTag> = ReminderTag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "tagID == %@", uuid as CVarArg)
        
        if let tag = try context.fetch(fetchRequest).first {
            context.delete(tag)
            try context.save()
            return .result(dialog: "Tag deleted")
        }
        throw TaskError.taskNotFound
    }
}

struct AddLocationIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Location"
    static var description: LocalizedStringResource = "Add a location to a task"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    @Parameter(title: "Location Name")
    var name: String
    
    @Parameter(title: "Latitude")
    var latitude: Double
    
    @Parameter(title: "Longitude")
    var longitude: Double
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Add Location: \(name)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            let location = Location(context: context)
            location.name = name
            location.latitude = latitude
            location.longitude = NSNumber(value: longitude)
            location.locationID = UUID()
            location.reminder = reminder
            try context.save()
            return .result(dialog: "Location added: \(name)")
        }
        throw TaskError.taskNotFound
    }
}

struct UpdateLocationIntent: AppIntent {
    static var title: LocalizedStringResource = "Update Location"
    static var description: LocalizedStringResource = "Update an existing location"
    
    @Parameter(title: "Location ID")
    var locationID: String
    
    @Parameter(title: "New Location Name")
    var newName: String
    
    @Parameter(title: "New Latitude")
    var newLatitude: Double
    
    @Parameter(title: "New Longitude")
    var newLongitude: Double
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Update Location: \(newName)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: locationID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "locationID == %@", uuid as CVarArg)
        
        if let location = try context.fetch(fetchRequest).first {
            location.name = newName
            location.latitude = newLatitude
            location.longitude = NSNumber(value: newLongitude)
            try context.save()
            return .result(dialog: "Location updated: \(newName)")
        }
        throw TaskError.taskNotFound
    }
}

struct DeleteLocationIntent: AppIntent {
    static var title: LocalizedStringResource = "Delete Location"
    static var description: LocalizedStringResource = "Remove a location from a task"
    
    @Parameter(title: "Location ID")
    var locationID: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Delete Location")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: locationID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "locationID == %@", uuid as CVarArg)
        
        if let location = try context.fetch(fetchRequest).first {
            context.delete(location)
            try context.save()
            return .result(dialog: "Location deleted")
        }
        throw TaskError.taskNotFound
    }
}

struct UpdatePriorityIntent: AppIntent {
    static var title: LocalizedStringResource = "Update Priority"
    static var description: LocalizedStringResource = "Change the priority level of a task"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    @Parameter(title: "Priority")
    var priority: Int
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Update Priority")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        guard priority >= 0 && priority <= 3 else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            reminder.priority = Int16(priority)
            try context.save()
            return .result(dialog: "Priority updated to \(priority)")
        }
        throw TaskError.taskNotFound
    }
}

struct DeletePriorityIntent: AppIntent {
    static var title: LocalizedStringResource = "Delete Priority"
    static var description: LocalizedStringResource = "Remove the priority setting from a task"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Delete Priority")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            reminder.priority = 0
            try context.save()
            return .result(dialog: "Priority removed")
        }
        throw TaskError.taskNotFound
    }
}

struct UpdateStartDateIntent: AppIntent {
    static var title: LocalizedStringResource = "Update Start Date"
    static var description: LocalizedStringResource = "Set or update the start date of a task"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    @Parameter(title: "Start Date")
    var startDate: Date
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Update Start Date")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            reminder.startDate = startDate
            try context.save()
            return .result(dialog: "Start date updated")
        }
        throw TaskError.taskNotFound
    }
}

struct DeleteStartDateIntent: AppIntent {
    static var title: LocalizedStringResource = "Delete Start Date"
    static var description: LocalizedStringResource = "Remove the start date from a task"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Delete Start Date")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            reminder.startDate = nil
            try context.save()
            return .result(dialog: "Start date removed")
        }
        throw TaskError.taskNotFound
    }
}

struct UpdateEndDateIntent: AppIntent {
    static var title: LocalizedStringResource = "Update End Date"
    static var description: LocalizedStringResource = "Set or update the due date of a task"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    @Parameter(title: "End Date")
    var endDate: Date
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Update End Date")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            reminder.endDate = endDate
            try context.save()
            return .result(dialog: "End date updated")
        }
        throw TaskError.taskNotFound
    }
}

struct DeleteEndDateIntent: AppIntent {
    static var title: LocalizedStringResource = "Delete End Date"
    static var description: LocalizedStringResource = "Remove the due date from a task"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Delete End Date")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            reminder.endDate = nil
            try context.save()
            return .result(dialog: "End date removed")
        }
        throw TaskError.taskNotFound
    }
}

struct AddPhotoIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Photo"
    static var description: LocalizedStringResource = "Add a photo to a task"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    @Parameter(title: "Photo File URL")
    var photoURL: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Add Photo")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        guard let url = URL(string: photoURL),
              let photoData = try? Data(contentsOf: url) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            let photo = ReminderPhoto(context: context)
            photo.photoData = photoData
            photo.order = Int16((reminder.photos?.count ?? 0) + 1)
            photo.reminder = reminder
            try context.save()
            return .result(dialog: "Photo added")
        }
        throw TaskError.taskNotFound
    }
}

struct UpdatePhotoIntent: AppIntent {
    static var title: LocalizedStringResource = "Update Photo"
    static var description: LocalizedStringResource = "Update an existing photo"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    @Parameter(title: "Photo Order")
    var photoOrder: Int
    
    @Parameter(title: "New Photo URL")
    var newPhotoURL: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Update Photo")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        guard let url = URL(string: newPhotoURL),
              let photoData = try? Data(contentsOf: url) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            let photoFetch: NSFetchRequest<ReminderPhoto> = ReminderPhoto.fetchRequest()
            photoFetch.predicate = NSPredicate(format: "reminder == %@ AND order == %d", reminder, photoOrder)
            
            if let photo = try context.fetch(photoFetch).first {
                photo.photoData = photoData
                try context.save()
                return .result(dialog: "Photo updated")
            }
        }
        throw TaskError.taskNotFound
    }
}

struct DeletePhotoIntent: AppIntent {
    static var title: LocalizedStringResource = "Delete Photo"
    static var description: LocalizedStringResource = "Remove a photo from a task"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    @Parameter(title: "Photo Order")
    var photoOrder: Int
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Delete Photo")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            let photoFetch: NSFetchRequest<ReminderPhoto> = ReminderPhoto.fetchRequest()
            photoFetch.predicate = NSPredicate(format: "reminder == %@ AND order == %d", reminder, photoOrder)
            
            if let photo = try context.fetch(photoFetch).first {
                context.delete(photo)
                try context.save()
                return .result(dialog: "Photo deleted")
            }
        }
        throw TaskError.taskNotFound
    }
}

struct AddListIntent: AppIntent {
    static var title: LocalizedStringResource = "Add List"
    static var description: LocalizedStringResource = "Create a new list to organize tasks"
    
    @Parameter(title: "Name")
    var name: String
    
    @Parameter(title: "Symbol")
    var symbol: String?
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Add List: \(name)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = PersistenceController.shared.persistentContainer.viewContext
        let list = TaskList(context: context)
        list.name = name
        list.symbol = symbol
        list.listID = UUID()
        list.createdAt = Date()
        try context.save()
        return .result(dialog: "List added: \(name)")
    }
}

struct UpdateListIntent: AppIntent {
    static var title: LocalizedStringResource = "Update List"
    static var description: LocalizedStringResource = "Update an existing list"
    
    @Parameter(title: "List ID")
    var listID: String
    
    @Parameter(title: "New Name")
    var newName: String
    
    @Parameter(title: "New Symbol")
    var newSymbol: String?
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Update List: \(newName)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: listID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<TaskList> = TaskList.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "listID == %@", uuid as CVarArg)
        
        if let list = try context.fetch(fetchRequest).first {
            list.name = newName
            list.symbol = newSymbol
            try context.save()
            return .result(dialog: "List updated: \(newName)")
        }
        throw TaskError.taskNotFound
    }
}

struct GetListIntent: AppIntent {
    static var title: LocalizedStringResource = "Get List"
    static var description: LocalizedStringResource = "Retrieve details of a specific list"
    
    @Parameter(title: "List ID")
    var listID: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Get List")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: listID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<TaskList> = TaskList.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "listID == %@", uuid as CVarArg)
        
        if let list = try context.fetch(fetchRequest).first {
            return .result(dialog: "List: \(list.name ?? "Untitled")")
        }
        throw TaskError.taskNotFound
    }
}

struct DeleteListIntent: AppIntent {
    static var title: LocalizedStringResource = "Delete List"
    static var description: LocalizedStringResource = "Delete a list and its contents"
    
    @Parameter(title: "List ID")
    var listID: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Delete List")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: listID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<TaskList> = TaskList.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "listID == %@", uuid as CVarArg)
        
        if let list = try context.fetch(fetchRequest).first {
            context.delete(list)
            try context.save()
            return .result(dialog: "List deleted")
        }
        throw TaskError.taskNotFound
    }
}

struct AddLinkIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Link"
    static var description: LocalizedStringResource = "Add a link to a task"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    @Parameter(title: "URL")
    var url: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Add Link")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        guard URL(string: url) != nil else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            reminder.url = url
            try context.save()
            return .result(dialog: "Link added")
        }
        throw TaskError.taskNotFound
    }
}

struct DeleteLinkIntent: AppIntent {
    static var title: LocalizedStringResource = "Delete Link"
    static var description: LocalizedStringResource = "Remove a link from a task"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Delete Link")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            reminder.url = nil
            try context.save()
            return .result(dialog: "Link deleted")
        }
        throw TaskError.taskNotFound
    }
}

struct UpdateLinkIntent: AppIntent {
    static var title: LocalizedStringResource = "Update Link"
    static var description: LocalizedStringResource = "Update the link of a task"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    @Parameter(title: "URL")
    var url: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Update Link")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        guard URL(string: url) != nil else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            reminder.url = url
            try context.save()
            return .result(dialog: "Link updated")
        }
        throw TaskError.taskNotFound
    }
}

struct AddSubheadingIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Subheading"
    static var description: LocalizedStringResource = "Add a subheading to organize tasks within a list"
    
    @Parameter(title: "List ID")
    var listID: String
    
    @Parameter(title: "Title")
    var title: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Add Subheading: \(title)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: listID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<TaskList> = TaskList.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "listID == %@", uuid as CVarArg)
        
        if let list = try context.fetch(fetchRequest).first {
            let subheading = SubHeading(context: context)
            subheading.title = title
            subheading.subheadingID = UUID()
            subheading.order = Int16((list.subHeadings?.count ?? 0) + 1)
            subheading.taskList = list
            try context.save()
            return .result(dialog: "Subheading added: \(title)")
        }
        throw TaskError.taskNotFound
    }
}

struct DeleteSubheadingIntent: AppIntent {
    static var title: LocalizedStringResource = "Delete Subheading"
    static var description: LocalizedStringResource = "Remove a subheading from a list"
    
    @Parameter(title: "Subheading ID")
    var subheadingID: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Delete Subheading")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: subheadingID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<SubHeading> = SubHeading.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "subheadingID == %@", uuid as CVarArg)
        
        if let subheading = try context.fetch(fetchRequest).first {
            context.delete(subheading)
            try context.save()
            return .result(dialog: "Subheading deleted")
        }
        throw TaskError.taskNotFound
    }
}

struct UpdateSubheadingIntent: AppIntent {
    static var title: LocalizedStringResource = "Update Subheading"
    static var description: LocalizedStringResource = "Update the title of a subheading"
    
    @Parameter(title: "Subheading ID")
    var subheadingID: String
    
    @Parameter(title: "Title")
    var title: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Update Subheading")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: subheadingID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<SubHeading> = SubHeading.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "subheadingID == %@", uuid as CVarArg)
        
        if let subheading = try context.fetch(fetchRequest).first {
            subheading.title = title
            try context.save()
            return .result(dialog: "Subheading updated")
        }
        throw TaskError.taskNotFound
    }
}

struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var description: LocalizedStringResource = "Mark a task as completed"
    
    @Parameter(title: "Task ID")
    var taskID: String
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "Complete Task")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: taskID) else {
            throw TaskError.invalidInput
        }
        
        let context = PersistenceController.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", uuid as CVarArg)
        
        if let reminder = try context.fetch(fetchRequest).first {
            reminder.isCompleted = true
            reminder.completedAt = Date()
            try context.save()
            return .result(dialog: "Task marked as complete")
        }
        throw TaskError.taskNotFound
    }
}

struct TaskManagerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: AddTaskIntent(),
                phrases: ["Add a task to Hexagon", "Create new task"],
                shortTitle: "Add Task",
                systemImageName: "plus.circle"
            ),
            AppShortcut(
                intent: AddListIntent(),
                phrases: ["Add a list to Hexagon", "Create new list"],
                shortTitle: "Add List",
                systemImageName: "list.bullet"
            ),
            AppShortcut(
                intent: AddSubheadingIntent(),
                phrases: ["Add a subheading", "Create new section"],
                shortTitle: "Add Subheading",
                systemImageName: "text.alignleft"
            ),
            AppShortcut(
                intent: CompleteTaskIntent(),
                phrases: ["Complete task", "Mark task as done"],
                shortTitle: "Complete Task",
                systemImageName: "checkmark.circle"
            ),
            AppShortcut(
                intent: DeleteTaskIntent(),
                phrases: ["Delete task", "Remove task"],
                shortTitle: "Delete Task",
                systemImageName: "trash"
            )
        ]
    }
}
