//
//  SubheadingHeader.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI


@MainActor
struct SubheadingHeader: View {
    let subHeading: SubHeading
    @StateObject private var subheadingViewModel: SubHeadingViewModel
    @State private var showEditAlert = false
    @State private var editText = ""
    @State private var showDeleteConfirmation = false
    @Environment(\.colorScheme) var colorScheme
    
    init(
        subHeading: SubHeading,
        performanceMonitor: PerformanceMonitoring = PerformanceMonitor()
    ) {
        self.subHeading = subHeading
        let subheadingManager = SubheadingService.shared
        
        _subheadingViewModel = StateObject(
            wrappedValue: SubHeadingViewModel(
                subheadingManager: subheadingManager,
                performanceMonitor: performanceMonitor
            )
        )
    }
    
    var body: some View {
        HStack {
            Text(subHeading.title ?? "")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Spacer()
            
            Menu {
                Button(action: {
                    editText = subHeading.title ?? ""
                    showEditAlert = true
                }) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: {
                    showDeleteConfirmation = true
                }) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.gray)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Subheading Options")
        }
        .alert("Edit Subheading", isPresented: $showEditAlert) {
            TextField("Title", text: $editText)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                Task {
                    do {
                        try await subheadingViewModel.updateSubHeading(subHeading, title: editText)
                    } catch {
                        print("Failed to update subheading:", error.localizedDescription)
                    }
                }
            }
        }
        .alert("Delete Subheading", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await subheadingViewModel.deleteSubHeading(subHeading)
                    } catch {
                        print("Failed to delete subheading:", error.localizedDescription)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this subheading? All associated tasks will be moved to the main list.")
        }
    }
}
