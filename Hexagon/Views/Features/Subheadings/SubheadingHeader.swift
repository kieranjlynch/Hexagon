//
//  SubheadingHeader.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI
import CoreData
import HexagonData

struct SubheadingHeader: View {
    @Environment(\.colorScheme) var colorScheme
    let subHeading: SubHeading
    @ObservedObject var viewModel: ListDetailViewModel
    @State private var isEditing = false
    @State private var title: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if isEditing {
                    TextField("Subheading name", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            updateSubheadingTitle()
                        }
                } else {
                    Text(subHeading.title ?? "Untitled")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                Spacer()
                Menu {
                    Button(action: {
                        isEditing = true
                        title = subHeading.title ?? ""
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(action: {
                        deleteSubheading()
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .padding()
                }
            }
        }
        .alert("Error", isPresented: $showError, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(errorMessage)
        })
    }
    
    private func updateSubheadingTitle() {
        isEditing = false
        Task {
            do {
                subHeading.title = title
                await viewModel.updateSubHeading(subHeading)
            }
        }
    }
    
    private func deleteSubheading() {
        Task {
            do {
                await viewModel.deleteSubHeading(subHeading)
            }
        }
    }
}
