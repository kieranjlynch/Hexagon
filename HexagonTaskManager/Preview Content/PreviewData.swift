import Foundation
import CoreData

class PreviewData {
    
    static var reminder: Reminder {
        let viewContext = CoreDataProvider.shared.persistentContainer.viewContext
        let request = Reminder.fetchRequest()
        return (try? viewContext.fetch(request).first) ?? Reminder(context: viewContext)
    }
    
    static var myList: TaskList {
        let viewContext = CoreDataProvider.shared.persistentContainer.viewContext
        let request = TaskList.fetchRequest()
        return (try? viewContext.fetch(request).first) ?? TaskList()
    }
    
}
