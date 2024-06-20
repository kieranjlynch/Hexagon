import SwiftUI
import PhotosUI

struct AddReminderView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [])
    private var tags: FetchedResults<Tag>
    @FetchRequest(sortDescriptors: [])
    private var lists: FetchedResults<TaskList>
    @FetchRequest(sortDescriptors: [])
    private var locations: FetchedResults<Location>
    
    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var selectedTag: String?
    @State private var selectedList: String?
    @State private var notes = ""
    @State private var url = ""
    @State private var priority = 0
    @State private var selectedPhotos: [UIImage] = []
    @State private var isShowingImagePicker = false
    
    var isFormValid: Bool {
        !title.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section {
                        HStack {
                            Text("Name")
                                .foregroundColor(.offWhite)
                                .padding(.trailing, 30)
                            TextField("", text: $title)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(10)
                                .background(Color.darkGray)
                                .foregroundColor(.offWhite)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.offWhite, lineWidth: 1)
                                )
                        }
                        .listRowBackground(Color.darkGray)
                        
                        DatePicker("Defer Date", selection: $startDate, displayedComponents: .date)
                            .foregroundColor(.offWhite)
                            .background(Color.darkGray)
                            .tint(.orange)
                            .environment(\.colorScheme, .dark)
                            .listRowBackground(Color.darkGray)
                        
                        DatePicker("Due Date", selection: $endDate, displayedComponents: .date)
                            .foregroundColor(.offWhite)
                            .background(Color.darkGray)
                            .tint(.orange)
                            .environment(\.colorScheme, .dark)
                            .listRowBackground(Color.darkGray)
                        
                        Section {
                            NavigationLink {
                                NotificationSheetView()
                            } label: {
                                Label("Notifications", systemImage: "app.badge.fill")
                                    .foregroundColor(.offWhite)
                            }
                            .padding(.vertical, 2)
                        }
                        .listRowBackground(Color.darkGray)
                        
                        NavigationLink {
                            TagsSheetView(tags: tags, selectedTag: Binding(get: {
                                tags.first(where: { $0.name == selectedTag })
                            }, set: { newValue in
                                selectedTag = newValue?.name
                            }))
                        } label: {
                            Label("Tags", systemImage: "tag")
                                .foregroundColor(.offWhite)
                        }
                        .padding(.vertical, 2)
                        .listRowBackground(Color.darkGray)
                        
                        NavigationLink {
                            PrioritySheetView(priority: $priority)
                        } label: {
                            Label("Priority", systemImage: "flag")
                                .foregroundColor(.offWhite)
                        }
                        .padding(.vertical, 2)
                        .listRowBackground(Color.darkGray)
                        
                        NavigationLink {
                            ListSheetView(lists: lists, selectedList: Binding(get: {
                                lists.first(where: { $0.name == selectedList })
                            }, set: { newValue in
                                selectedList = newValue?.name
                            }))
                        } label: {
                            Label("List", systemImage: "list.bullet")
                                .foregroundColor(.offWhite)
                        }
                        .padding(.vertical, 2)
                        .listRowBackground(Color.darkGray)
                        
                        NavigationLink {
                            NotesSheetView(notes: $notes)
                        } label: {
                            Label("Notes", systemImage: "note.text")
                                .foregroundColor(.offWhite)
                        }
                        .padding(.vertical, 2)
                        .listRowBackground(Color.darkGray)
                        
                        NavigationLink {
                            PhotosSheetView(selectedPhotos: Binding(get: {
                                selectedPhotos
                            }, set: { newValue in
                                selectedPhotos = newValue
                            }))
                        } label: {
                            Label("Photos", systemImage: "photo.badge.plus")
                                .foregroundColor(.offWhite)
                        }
                        .padding(.vertical, 2)
                        .listRowBackground(Color.darkGray)
                    }
                    .listRowBackground(Color.darkGray)
                }
                .background(Color.darkGray.ignoresSafeArea())
                .scrollContentBackground(.hidden)
                
                HStack {
                    CancelButton(cancelAction: { presentationMode.wrappedValue.dismiss() })
                    SubmitButton(submitAction: saveReminder)
                }
                .padding()
                .background(Color.darkGray)
            }
            .background(Color.darkGray.ignoresSafeArea())
            .foregroundColor(.offWhite)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.darkGray, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private func saveReminder() {
        guard !title.isEmpty else { return }
        
        let reminder = Reminder(context: viewContext)
        reminder.title = title
        reminder.startDate = startDate
        reminder.endDate = endDate
        reminder.notes = notes
        reminder.url = url
        reminder.priority = Int16(priority)
        reminder.tag = selectedTag
        if let selectedListName = selectedList {
            reminder.list = lists.first(where: { $0.name == selectedListName })
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
