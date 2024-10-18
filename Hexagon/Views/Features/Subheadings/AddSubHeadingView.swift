//
//  AddSubHeadingView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI
import CoreData
import HexagonData

struct AddSubHeadingView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State private var title: String = ""
    @State private var subHeadingsCount: Int = 0
    @State private var errorMessage: String?
    @State private var isErrorPresented: Bool = false
    
    let taskList: TaskList
    let onSave: (SubHeading) -> Void
    let context: NSManagedObjectContext
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Sub-heading Title", text: $title)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
            .navigationBarTitle("Add Sub-heading", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveSubHeading()
                }
                    .disabled(title.isEmpty)
            )
        }
        .onAppear {
            fetchSubHeadingsCount()
        }
        .alert(isPresented: $isErrorPresented) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
    }
    
    private func saveSubHeading() {
        Task {
            do {
                let subheadingService = SubheadingService()
                let newSubHeading = try await subheadingService.saveSubHeading(
                    title: title,
                    taskList: taskList
                )
                onSave(newSubHeading)
                presentationMode.wrappedValue.dismiss()
            } catch {
                errorMessage = "Failed to save subheading: \(error.localizedDescription)"
                isErrorPresented = true
            }
        }
    }
    
    private func fetchSubHeadingsCount() {
        Task {
            do {
                let subheadingService = SubheadingService()
                subHeadingsCount = try await subheadingService.fetchSubHeadingsCount(for: taskList)
            } catch {
                errorMessage = "Failed to fetch subheadings count: \(error.localizedDescription)"
                isErrorPresented = true
            }
        }
    }
}
