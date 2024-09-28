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
                    TextField("Subheading name", text: $title, onCommit: {
                        isEditing = false
                        Task {
                            do {
                                subHeading.title = title
                                try await viewModel.updateSubHeading(subHeading)
                            } catch {
                                showError = true
                                errorMessage = error.localizedDescription
                            }
                        }
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
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
                        Task {
                            do {
                                try await viewModel.deleteSubHeading(subHeading)
                            } catch {
                                showError = true
                                errorMessage = error.localizedDescription
                            }
                        }
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .padding()
                }
            }
            
            Divider()
                .background(Color.gray.opacity(0.5))
                .padding(.top, 4)
        }
        .alert("Error", isPresented: $showError, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(errorMessage)
        })
    }
}
