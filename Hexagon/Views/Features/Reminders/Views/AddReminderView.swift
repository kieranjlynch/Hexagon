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
    
    private var mainContent: some View {
        VStack {
            List {
                TitleFieldView(title: Binding(
                    get: { viewModel.title },
                    set: { viewModel.title = $0 }
                ), taskType: preferredTaskType, colorScheme: _colorScheme)
                .listRowSeparator(.hidden, edges: .all)
                .padding(.top, 8)
                
                DateFieldsView(
                    startDate: Binding(
                        get: { viewModel.startDate },
                        set: { viewModel.startDate = $0 }
                    ),
                    endDate: Binding(
                        get: { viewModel.endDate },
                        set: { viewModel.endDate = $0 }
                    ),
                    colorScheme: colorScheme
                )
                .listRowSeparator(.hidden, edges: .all)
                
                RepeatFieldView(
                    repeatOption: Binding(
                        get: { viewModel.repeatOption },
                        set: { viewModel.repeatOption = $0 }
                    ),
                    customRepeatInterval: Binding(
                        get: { viewModel.customRepeatInterval },
                        set: { viewModel.customRepeatInterval = $0 }
                    ),
                    colorScheme: colorScheme
                )
                .listRowSeparator(.hidden, edges: .all)
                
                ListFieldView(
                    selectedList: Binding(
                        get: { viewModel.selectedList },
                        set: { viewModel.selectedList = $0 }
                    ),
                    colorScheme: colorScheme
                )
                .listRowSeparator(.hidden, edges: .all)
                
                PriorityFieldView(
                    priority: Binding(
                        get: { viewModel.priority },
                        set: { viewModel.priority = $0 }
                    ),
                    colorScheme: colorScheme
                )
                .listRowSeparator(.hidden, edges: .all)
                
                LinkFieldView(
                    url: Binding(
                        get: { viewModel.url },
                        set: { viewModel.url = $0 }
                    ),
                    colorScheme: colorScheme
                )
                .listRowSeparator(.hidden, edges: .all)
                
                NotificationsFieldView(
                    selectedNotifications: Binding(
                        get: { viewModel.selectedNotifications },
                        set: { viewModel.selectedNotifications = $0 }
                    ),
                    colorScheme: colorScheme
                )
                .environmentObject(fetchingService)
                .listRowSeparator(.hidden, edges: .all)
                
                TagsFieldView(
                    selectedTags: Binding(
                        get: { viewModel.selectedTags },
                        set: { viewModel.selectedTags = $0 }
                    ),
                    colorScheme: colorScheme
                )
                .listRowSeparator(.hidden, edges: .all)
                
                NotesFieldView(
                    notes: Binding(
                        get: { viewModel.notes },
                        set: { viewModel.notes = $0 }
                    ),
                    colorScheme: colorScheme
                )
                .listRowSeparator(.hidden, edges: .all)
                
                VoiceNoteFieldView(
                    voiceNoteData: Binding(
                        get: { viewModel.voiceNoteData },
                        set: { viewModel.voiceNoteData = $0 }
                    ),
                    colorScheme: colorScheme
                )
                .listRowSeparator(.hidden, edges: .all)
                .padding(.bottom, 0)
                
                PhotosFieldView(
                    selectedPhotos: Binding(
                        get: { viewModel.selectedPhotos },
                        set: { viewModel.selectedPhotos = $0 }
                    ),
                    colorScheme: colorScheme,
                    isShowingImagePicker: Binding(
                        get: { viewModel.isShowingImagePicker },
                        set: { viewModel.isShowingImagePicker = $0 }
                    ),
                    expandedPhotoIndex: Binding(
                        get: { viewModel.expandedPhotoIndex },
                        set: { viewModel.expandedPhotoIndex = $0 }
                    )
                )
                .listRowSeparator(.hidden, edges: .all)
                .padding(.top, 0)
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
