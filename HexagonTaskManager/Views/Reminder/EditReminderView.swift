import SwiftUI
import PhotosUI
import SharedDataFramework

struct EditReminderView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)])
    private var tags: FetchedResults<Tag>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \TaskList.name, ascending: true)])
    private var lists: FetchedResults<TaskList>
    
    var reminder: Reminder
    
    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var selectedTag: Tag?
    @State private var selectedList: TaskList?
    @State private var notes: String
    @State private var url: String
    @State private var priority: Int
    @State private var selectedPhotos: [UIImage] = []
    @State private var isShowingImagePicker = false
    @State private var showNewListView = false
    
    private let reminderService = ReminderService()
    
    var isFormValid: Bool {
        !title.isEmpty
    }
    
    init(reminder: Reminder) {
        self.reminder = reminder
        _title = State(initialValue: reminder.title ?? "")
        _startDate = State(initialValue: reminder.startDate ?? Date())
        _endDate = State(initialValue: reminder.endDate ?? Date())
        _selectedTag = State(initialValue: reminder.tagsArray.first)
        _selectedList = State(initialValue: reminder.list)
        _notes = State(initialValue: reminder.notes ?? "")
        _url = State(initialValue: reminder.url ?? "")
        _priority = State(initialValue: Int(reminder.priority))
        _selectedPhotos = State(initialValue: reminder.photosArray.compactMap { UIImage(data: $0.photoData ?? Data()) })
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkGray.ignoresSafeArea()
                
                VStack {
                    Form {
                        Section(header: Label("Reminder", systemImage: "square.and.pencil")) {
                            TextField("Name", text: $title)
                                .foregroundColor(.offWhite)
                        }
                        .listRowBackground(Color.customBackgroundColor)
                        .environment(\.colorScheme, .dark)
                        
                        Section(header: Label("Dates & Times", systemImage: "calendar")) {
                            DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                                .foregroundColor(.offWhite)
                                .tint(.orange)
                            
                            DatePicker("End Date", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                                .foregroundColor(.offWhite)
                                .tint(.orange)
                        }
                        .listRowBackground(Color.customBackgroundColor)
                        .environment(\.colorScheme, .dark)
                        
                        Section(header: Label("Priority", systemImage: "flag")) {
                            Picker("", selection: $priority) {
                                Text("Low")
                                    .foregroundColor(.offWhite)
                                    .tag(0)
                                Text("Medium")
                                    .foregroundColor(.offWhite)
                                    .tag(1)
                                Text("High")
                                    .foregroundColor(.offWhite)
                                    .tag(2)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .tint(.orange)
                        }
                        .listRowBackground(Color.customBackgroundColor)
                        .environment(\.colorScheme, .dark)
                        
                        Section(header: Label("Tags", systemImage: "tag")) {
                            HStack {
                                Spacer()
                                Button(action: {
                                    addNewTag()
                                }) {
                                    Image(systemName: "plus")
                                        .foregroundColor(.offWhite)
                                }
                                Spacer()
                                Picker("", selection: $selectedTag) {
                                    Text("None").tag(nil as Tag?)
                                    ForEach(tags) { tag in
                                        Text(tag.name ?? "").tag(tag as Tag?)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .tint(.orange)
                                Spacer()
                            }
                            .listRowBackground(Color.customBackgroundColor)
                        }
                        
                        Section(header: Label("List", systemImage: "list.bullet")) {
                            HStack {
                                Spacer()
                                
                                Button(action: {
                                    showNewListView = true
                                }) {
                                    Image(systemName: "plus")
                                        .foregroundColor(.offWhite)
                                }
                                .sheet(isPresented: $showNewListView) {
                                    AddNewListView { name, color, symbol in
                                        do {
                                            try reminderService.saveTaskList(name, color, symbol)
                                        } catch {
                                            print("Failed to save new list: \(error)")
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Picker("", selection: $selectedList) {
                                    Text("None").tag(nil as TaskList?)
                                    ForEach(lists) { list in
                                        Text(list.name!).tag(list as TaskList?)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .tint(.orange)
                                Spacer()
                            }
                            .listRowBackground(Color.customBackgroundColor)
                        }
                        
                        Section(header: Label("Photos", systemImage: "photo.badge.plus")) {
                            Button(action: {
                                isShowingImagePicker = true
                            }) {
                                Image(systemName: "plus")
                                    .foregroundColor(.offWhite)
                            }
                            
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(selectedPhotos, id: \.self) { photo in
                                        Image(uiImage: photo)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 100)
                                    }
                                }
                            }
                            .sheet(isPresented: $isShowingImagePicker) {
                                ImagePicker(selectedImages: $selectedPhotos)
                            }
                        }
                        .listRowBackground(Color.customBackgroundColor)
                        
                        Section(header: Label("Notes", systemImage: "note.text")) {
                            TextField("", text: $notes, axis: .vertical)
                                .foregroundColor(.offWhite)
                                .lineLimit(1...5)
                            
                        }
                        .listRowBackground(Color.customBackgroundColor)
                        
                        Section(header: Label("Link", systemImage: "link")) {
                            TextField("", text: $url)
                                .foregroundColor(.offWhite)
                        }
                        .listRowBackground(Color.customBackgroundColor)
                        
                        Section(header: Label("", systemImage: "")) {
                            
                        }
                        .listRowBackground(Color.customBackgroundColor)
                        
                        
                    }
                    .foregroundColor(.offWhite)
                    .scrollContentBackground(.hidden)
                    .navigationTitle("Edit Reminder")
                    .navigationBarTitleDisplayMode(.inline)
                }
                
                
            }
        }
    }
    
    private func addNewTag() {
        let alert = UIAlertController(title: "New Tag", message: "Enter a new tag name", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Tag name"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let textField = alert.textFields?.first,
               let tagName = textField.text, !tagName.isEmpty {
                let newTag = Tag(context: viewContext)
                newTag.name = tagName
                
                do {
                    try viewContext.save()
                } catch {
                    print("Failed to save new tag: \(error)")
                }
            }
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true, completion: nil)
        }
    }
    
    private func saveReminder() {
        guard !title.isEmpty else {
            return
        }
        
        reminder.title = title
        reminder.startDate = startDate
        reminder.endDate = endDate
        reminder.notes = notes
        reminder.url = url
        reminder.priority = Int16(priority)
        reminder.tag = selectedTag?.name
        if let selectedList = selectedList {
            reminder.list = selectedList
        }
        let photosSet = NSMutableSet(array: selectedPhotos.compactMap { photo in
            let reminderPhoto = ReminderPhoto(context: viewContext)
            reminderPhoto.photoData = photo.pngData()
            return reminderPhoto
        })
        reminder.addToPhotos(photosSet)
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save reminder: \(error)")
        }
    }
}
