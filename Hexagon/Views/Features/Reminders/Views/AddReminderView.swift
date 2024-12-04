//
//  AddReminderView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import PhotosUI
import CoreData

public struct AddReminderView: View {
    @StateObject private var viewModel: AddReminderViewModel
    @EnvironmentObject public var fetchingService: ReminderFetchingServiceUI
    @EnvironmentObject public var modificationService: ReminderModificationService
    @EnvironmentObject public var listService: ListService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("preferredTaskType") private var preferredTaskType: String = "Tasks"
    public var onSave: ((Reminder, [String], [UIImage]) -> Void)?
    
    public init(
        reminder: Reminder? = nil,
        defaultList: TaskList? = nil,
        persistentContainer: NSPersistentContainer,
        fetchingService: ReminderFetchingServiceUI,
        modificationService: ReminderModificationService,
        tagService: TagService,
        listService: ListService,
        onSave: ((Reminder, [String], [UIImage]) -> Void)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: AddReminderViewModel(
                reminder: reminder,
                defaultList: defaultList,
                reminderCreator: modificationService,
                taskLimitChecker: listService,
                tagService: tagService,
                listService: listService
            )
        )
        self.onSave = onSave
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                switch viewModel.viewState {
                case .loading:
                    ProgressView()
                case .error(let errorMessage):
                    ErrorView(error: errorMessage) {
                        viewModel.updateViewState(.idle)
                    }
                default:
                    mainContent
                }
            }
            .navigationBarSetup(
                title: viewModel.reminder == nil ? "Add \(preferredTaskType.dropLast())" : "Edit \(preferredTaskType.dropLast())"
            )
        }
        .onAppear {
            DateFormatter.updateSharedDateFormatter()
        }
        .sheet(isPresented: Binding(
            get: { viewModel.isShowingImagePicker },
            set: { viewModel.isShowingImagePicker = $0 }
        )) {
            ImagePicker(selectedImages: Binding(
                get: { viewModel.selectedPhotos },
                set: { viewModel.selectedPhotos = $0 }
            ))
        }
        .newTagAlert(
            isShowingNewTagAlert: Binding(
                get: { viewModel.isShowingNewTagAlert },
                set: { viewModel.isShowingNewTagAlert = $0 }
            ),
            newTagName: Binding(
                get: { viewModel.newTagName },
                set: { viewModel.newTagName = $0 }
            ),
            addAction: { Task { try await viewModel.addNewTag() } }
        )
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK", role: .cancel) {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error.message)
            }
        }
    }
    
    struct NotesButton: View {
        @Binding var notes: String
        var colorScheme: ColorScheme
        @State private var showingNotesSheet = false
        
        var body: some View {
            Button {
                showingNotesSheet = true
            } label: {
                Text("Add Notes")
                    .foregroundColor(.blue)
            }
            .sheet(isPresented: $showingNotesSheet) {
                NotesSheetView(notes: $notes)
            }
        }
    }
    
    struct GridFieldsView: View {
        @Binding var startDate: Date
        @Binding var endDate: Date?
        @Binding var repeatOption: RepeatOption
        @Binding var customRepeatInterval: Int
        @Binding var selectedList: TaskList?
        @Binding var priority: Int
        @Binding var selectedNotifications: Set<String>
        @Binding var selectedTags: Set<ReminderTag>
        @Binding var voiceNoteData: Data?
        @Binding var notes: String
        @Binding var selectedPhotos: [UIImage]
        @Binding var isShowingImagePicker: Bool
        @Binding var expandedPhotoIndex: Int?
        @Binding var url: String
        var colorScheme: ColorScheme
        
        var body: some View {
            Grid(alignment: .leading, horizontalSpacing: 32, verticalSpacing: 20) {
                GridRow {
                    Label("Start", systemImage: "calendar")
                        .foregroundColor(.primary)
                    Label("Due", systemImage: "calendar")
                        .foregroundColor(.primary)
                }
                
                GridRow {
                    DatePicker("", selection: $startDate, displayedComponents: [.date])
                        .labelsHidden()
                    DatePicker("", selection: Binding(
                        get: { endDate ?? startDate },
                        set: { endDate = $0 }
                    ), displayedComponents: [.date])
                    .labelsHidden()
                }
                
                GridRow {
                    Label("Repeat", systemImage: "arrow.clockwise")
                        .foregroundColor(.primary)
                    Label("List", systemImage: "list.bullet")
                        .foregroundColor(.primary)
                }
                
                GridRow {
                    RepeatFieldView(repeatOption: $repeatOption, customRepeatInterval: $customRepeatInterval, colorScheme: colorScheme)
                    ListFieldView(selectedList: $selectedList, colorScheme: colorScheme)
                }
                
                GridRow {
                    Label("Priority", systemImage: "flag")
                        .foregroundColor(.primary)
                    Label("Notifications", systemImage: "app.badge.fill")
                        .foregroundColor(.primary)
                }
                
                GridRow {
                    PriorityFieldView(priority: $priority, colorScheme: colorScheme)
                    NotificationsFieldView(selectedNotifications: $selectedNotifications, colorScheme: colorScheme)
                }
                
                GridRow {
                    Label("Tags", systemImage: "tag")
                        .foregroundColor(.primary)
                    Label("Voice Note", systemImage: "mic")
                        .foregroundColor(.primary)
                }
                
                GridRow {
                    TagsFieldView(selectedTags: $selectedTags, colorScheme: colorScheme)
                    Button {
                    } label: {
                        Text(voiceNoteData == nil ? "Record" : "Re-record")
                            .foregroundColor(.blue)
                    }
                }
                
                GridRow {
                    Label("Notes", systemImage: "note.text")
                        .foregroundColor(.primary)
                    Label("Photos", systemImage: "photo")
                        .foregroundColor(.primary)
                }
                
                GridRow {
                    NotesButton(notes: $notes, colorScheme: colorScheme)
                    Button {
                        isShowingImagePicker = true
                    } label: {
                        Text(selectedPhotos.isEmpty ? "Add Photos" : "\(selectedPhotos.count) Photos")
                            .foregroundColor(.blue)
                    }
                }
                
                GridRow {
                    Label("Link", systemImage: "link")
                        .foregroundColor(.primary)
                        .gridCellColumns(2)
                }
                
                GridRow {
                    TextField("Add URL", text: $url)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .gridCellColumns(2)
                }
            }
        }
    }
    
    private var mainContent: some View {
        VStack {
            List {
                Group {
                    TitleFieldView(title: $viewModel.title, taskType: preferredTaskType, colorScheme: _colorScheme)
                        .listRowSeparator(.hidden)
                        .padding(.top, 8)
                    
                    GridFieldsView(
                        startDate: $viewModel.startDate,
                        endDate: $viewModel.endDate,
                        repeatOption: $viewModel.repeatOption,
                        customRepeatInterval: $viewModel.customRepeatInterval,
                        selectedList: $viewModel.selectedList,
                        priority: $viewModel.priority,
                        selectedNotifications: $viewModel.selectedNotifications,
                        selectedTags: $viewModel.selectedTags,
                        voiceNoteData: $viewModel.voiceNoteData,
                        notes: $viewModel.notes,
                        selectedPhotos: $viewModel.selectedPhotos,
                        isShowingImagePicker: $viewModel.isShowingImagePicker,
                        expandedPhotoIndex: $viewModel.expandedPhotoIndex,
                        url: $viewModel.url,
                        colorScheme: colorScheme
                    )
                    .listRowSeparator(.hidden)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .listRowBackground(Color.clear)
            .scrollContentBackground(.hidden)
            .adaptiveBackground()
            
            ButtonRowView(
                isFormValid: viewModel.isFormValid,
                saveAction: { Task { await save() } },
                dismissAction: { dismiss() },
                colorScheme: colorScheme
            )
        }
        .overlay(expandedPhotoOverlay)
    }
    
    private var expandedPhotoOverlay: some View {
        Group {
            if let index = viewModel.expandedPhotoIndex, index < viewModel.selectedPhotos.count {
                ZStack {
                    Color.black.opacity(0.8).ignoresSafeArea()
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { viewModel.expandedPhotoIndex = nil }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }
                        Image(uiImage: viewModel.selectedPhotos[index])
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                    }
                }
            }
        }
    }
    
    private func save() async {
        do {
            let (savedReminder, updatedTags, updatedPhotos) = try await viewModel.saveReminder()
            viewModel.updatePhotos(updatedPhotos)
            NotificationCenter.default.post(name: .reminderAdded, object: nil)
            onSave?(savedReminder, updatedTags, updatedPhotos)
            dismiss()
        } catch {
            viewModel.error = IdentifiableError(message: error.localizedDescription)
        }
    }
}

extension NSNotification.Name {
    static let reminderAdded = NSNotification.Name("reminderAdded")
}

//struct AddReminderView_Previews: PreviewProvider {
//    static var previews: some View {
//        let persistenceController = PersistenceController.inMemoryController()
//        
//        let fetchingService = ReminderFetchingServiceUI()
//        let modificationService = ReminderModificationService(persistenceController: persistenceController)
//        let tagService = TagService(persistenceController: persistenceController)
//        let listService = ListService(persistenceController: persistenceController)
//        
//        let appSettings = AppSettings()
//        
//        AddReminderView(
//            persistentContainer: persistenceController.persistentContainer,
//            fetchingService: fetchingService,
//            modificationService: modificationService,
//            tagService: tagService,
//            listService: listService
//        )
//        .environmentObject(fetchingService)
//        .environmentObject(modificationService)
//        .environmentObject(listService)
//        .environmentObject(appSettings)
//        .previewDisplayName("Add Reminder View")
//    }
//}
//
//extension PersistenceController {
//    static func createPreviewContainer() -> NSPersistentContainer {
//        let container = NSPersistentContainer(name: "HexagonModel")
//        let description = NSPersistentStoreDescription()
//        description.type = NSInMemoryStoreType
//        container.persistentStoreDescriptions = [description]
//        
//        container.loadPersistentStores { description, error in
//            if let error = error {
//                fatalError("Unable to load persistent stores: \(error)")
//            }
//        }
//        
//        return container
//    }
//}
