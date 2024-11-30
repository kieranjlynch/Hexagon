//
//  AddSubHeadingView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI

import CoreData

struct AddSubHeadingView: View {
    let taskList: TaskList
    let onSave: (SubHeading) -> Void
    let context: NSManagedObjectContext
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var title = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let subheadingService = SubheadingService.shared
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TitleTextField(text: $title)
                }
            }
            .navigationTitle("New Section")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveSubHeading()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveSubHeading() {
        Task {
            do {
                let subHeading = try await subheadingService.saveSubHeading(
                    title: title,
                    taskList: taskList
                )
                onSave(subHeading)
                dismiss()
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
}
