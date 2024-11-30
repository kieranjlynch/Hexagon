import SwiftUI
import CoreData
import os


struct TagsSheetView: View {
    @Environment(\.appTintColor) var appTintColor
    @Environment(\.colorScheme) var colorScheme
    @State private var tags: [ReminderTag] = []
    @Binding var selectedTags: Set<ReminderTag>
    @State private var isShowingNewTagAlert = false
    @State private var newTagName = ""
    @EnvironmentObject private var fetchingService: ReminderFetchingServiceUI
    @EnvironmentObject private var modificationService: ReminderModificationService
    
    @State private var errorMessage: String?
    private let logger = Logger(subsystem: Constants.General.appBundleIdentifier, category: "TagsSheetView")
    
    private let tagService: TagService
    
    init(selectedTags: Binding<Set<ReminderTag>>) {
        self._selectedTags = selectedTags
        self.tagService = TagService()
    }
    
    var body: some View {
        List {
            ForEach(tags) { tag in
                TagRowView(tag: tag, isSelected: selectedTags.contains(tag), appTintColor: appTintColor) {
                    toggleTag(tag)
                }
            }
            
            Button(action: {
                isShowingNewTagAlert = true
            }) {
                Text("Add New Tag")
                    .adaptiveColors()
            }
        }
        .listStyle(PlainListStyle())
        .listSettings()
        .newTagAlert(
            isShowingNewTagAlert: $isShowingNewTagAlert,
            newTagName: $newTagName,
            addAction: { Task { await addNewTag() } }
        )
        .task {
            await fetchTags()
        }
        .errorAlert(errorMessage: $errorMessage)
    }
    
    private func toggleTag(_ tag: ReminderTag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    private func addNewTag() async {
        guard !newTagName.isEmpty else { return }
        do {
            let newTag = try await tagService.createTag(name: newTagName)
            selectedTags.insert(newTag)
            newTagName = ""
            await fetchTags()
        } catch {
            logger.error("Failed to save new tag: \(error)")
            errorMessage = "Failed to create new tag: \(error.localizedDescription)"
        }
    }
    
    private func fetchTags() async {
        do {
            tags = try await tagService.fetchTags()
        } catch {
            logger.error("Failed to fetch tags: \(error)")
            errorMessage = "Failed to fetch tags: \(error.localizedDescription)"
        }
    }
}
