import CoreData
import SharedDataFramework

extension Reminder {
    var tagsArray: [Tag] {
        if let tag = tags {
            return [tag]
        } else {
            return []
        }
    }
    
    var photosArray: [ReminderPhoto] {
        let set = photos as? Set<ReminderPhoto> ?? []
        return set.sorted { (photo1: ReminderPhoto, photo2: ReminderPhoto) -> Bool in
            (photo1.photoData?.count ?? 0) < (photo2.photoData?.count ?? 0)
        }
    }
    
    var locationArray: [Location] {
        let set = location != nil ? Set([location!]) : Set<Location>()
        return set.sorted { (loc1: Location, loc2: Location) -> Bool in
            (loc1.name ?? "") < (loc2.name ?? "")
        }
    }
    
    var locationName: String {
        location?.name ?? "No Location"
    }
}
