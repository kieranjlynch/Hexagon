import Foundation
import CoreData

public class CoreDataProvider {
    public static let shared = CoreDataProvider() 
    public let persistentContainer: NSPersistentContainer
    
    private init() {
        ValueTransformer.setValueTransformer(UIColorTransformer(), forName: NSValueTransformerName("UIColorTransformer"))
        
        persistentContainer = NSPersistentContainer(name: "HexagonModel")
        
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.klynch.Hexagon") else {
            fatalError("Unable to find shared app group")
        }
        
        let storeURL = appGroupURL.appendingPathComponent("HexagonModel.sqlite")
        let description = NSPersistentStoreDescription(url: storeURL)
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { (description, error) in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
    }
    
    public func saveLocation(name: String, latitude: Double, longitude: Double) throws {
        let context = self.persistentContainer.viewContext
        let location = Location(context: context)
        location.name = name
        location.latitude = latitude
        location.longitude = longitude
        try context.save()
    }
    
    public func fetchLocations() -> [Location] {
        let context = self.persistentContainer.viewContext
        let request = Location.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch locations: \(error)")
            return []
        }
    }
}
