import Foundation
import CoreData

class CoreDataProvider {
    static let shared = CoreDataProvider()
    let persistentContainer: NSPersistentContainer
    
    private init() {
        ValueTransformer.setValueTransformer(UIColorTransformer(), forName: NSValueTransformerName("UIColorTransformer"))
        
        persistentContainer = NSPersistentContainer(name: "HexagonModel")
        persistentContainer.loadPersistentStores { description, error in
            if let error {
                fatalError("Error initializing HexagonModel \(error)")
            }
        }
    }
    
    func saveLocation(name: String, latitude: Double, longitude: Double) throws {
        let context = persistentContainer.viewContext
        let location = Location(context: context)
        location.name = name
        location.latitude = latitude
        location.longitude = longitude
        try context.save()
    }
    
    func fetchLocations() -> [Location] {
        let context = persistentContainer.viewContext
        let request = Location.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch locations: \(error)")
            return []
        }
    }
}
