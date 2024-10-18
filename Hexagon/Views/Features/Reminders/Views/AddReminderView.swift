//
//  AddReminderView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import PhotosUI
import HexagonData

public struct AddReminderView: View {
    @StateObject private var viewModel: AddReminderViewModel
    @EnvironmentObject public var reminderService: ReminderService
    @EnvironmentObject public var listService: ListService
    @EnvironmentObject public var locationService: LocationService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("preferredTaskType") private var preferredTaskType: String = "Tasks"
    public var onSave: ((Reminder, [String], [UIImage]) -> Void)?
    
    public init(reminder: Reminder? = nil, defaultList: TaskList? = nil, onSave: ((Reminder, [String], [UIImage]) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: AddReminderViewModel(reminder: reminder, defaultList: defaultList))
        self.onSave = onSave
    }
    
    public var body: some View {
        NavigationStack {
            VStack {
                List {
                    TitleFieldView(title: $viewModel.title, taskType: preferredTaskType, colorScheme: colorScheme)
                        .listRowSeparator(.hidden, edges: .all)
                        .padding(.top, 8)
                    
                    DateFieldsView(startDate: $viewModel.startDate, endDate: $viewModel.endDate, colorScheme: colorScheme)
                        .listRowSeparator(.hidden, edges: .all)
                    
                    ListFieldView(selectedList: $viewModel.selectedList, colorScheme: colorScheme)
                        .listRowSeparator(.hidden, edges: .all)
                    
                    PriorityFieldView(priority: $viewModel.priority, colorScheme: colorScheme)
                        .listRowSeparator(.hidden, edges: .all)
                    
                    LinkFieldView(url: $viewModel.url, colorScheme: colorScheme)
                        .listRowSeparator(.hidden, edges: .all)
                    
                    NotificationsFieldView(selectedNotifications: $viewModel.selectedNotifications, colorScheme: colorScheme)
                        .environmentObject(reminderService)
                        .listRowSeparator(.hidden, edges: .all)
                    
                    TagsFieldView(selectedTags: $viewModel.selectedTags, colorScheme: colorScheme)
                        .listRowSeparator(.hidden, edges: .all)
                    
                    NotesFieldView(notes: $viewModel.notes, colorScheme: colorScheme)
                        .listRowSeparator(.hidden, edges: .all)
                    
                    VoiceNoteFieldView(voiceNoteData: $viewModel.voiceNoteData, colorScheme: colorScheme)
                        .listRowSeparator(.hidden, edges: .all)
                    
                    PhotosFieldView(selectedPhotos: $viewModel.selectedPhotos, colorScheme: colorScheme, isShowingImagePicker: $viewModel.isShowingImagePicker, expandedPhotoIndex: $viewModel.expandedPhotoIndex)
                        .listRowSeparator(.hidden, edges: .all)
                }
                .listRowBackground(Color.clear)
                             .scrollContentBackground(.hidden)
                             .adaptiveBackground()
                             
                             ButtonRowView(
                                 isFormValid: viewModel.isFormValid,
                                 saveAction: { await save() },
                                 dismissAction: { dismiss() },
                                 colorScheme: colorScheme
                             )
                         }
                         .navigationBarSetup(
                             title: viewModel.reminder == nil ? "Add \(preferredTaskType.dropLast())" : "Edit \(preferredTaskType.dropLast())"
                         )
                         .overlay(expandedPhotoOverlay)
                     }
        .onAppear {
            viewModel.reminderService = reminderService
            viewModel.locationService = locationService
            viewModel.listService = listService
            DateFormatter.updateSharedDateFormatter()
        }
        .sheet(isPresented: $viewModel.isShowingImagePicker) {
            ImagePicker(selectedImages: $viewModel.selectedPhotos)
        }
        .newTagAlert(
            isShowingNewTagAlert: $viewModel.isShowingNewTagAlert,
            newTagName: $viewModel.newTagName,
            addAction: { Task { try await viewModel.addNewTag() } }
        )
        .errorAlert(errorMessage: $viewModel.errorMessage)
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
            
            if viewModel.selectedList != nil {
               
            }
            
            dismiss()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}
