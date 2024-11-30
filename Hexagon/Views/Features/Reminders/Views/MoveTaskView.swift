//
//  MoveTaskView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI

import CoreData

struct MoveTaskView: View {
    let reminder: Reminder
    let onMove: (TaskList) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedList: TaskList?
    @State private var lists: [TaskList] = []
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            List(lists, id: \.objectID) { list in
                if list.objectID != reminder.list?.objectID {
                    Button(action: {
                        selectedList = list
                        onMove(list)
                    }) {
                        HStack {
                            Image(systemName: list.symbol ?? "list.bullet")
                                .foregroundColor(getListColor(from: list.colorData))
                            Text(list.name ?? "")
                        }
                    }
                }
            }
            .navigationTitle("Move to List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                do {
                    lists = try await ListService.shared.fetchAllLists()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private func getListColor(from colorData: Data?) -> Color {
        guard let colorData = colorData,
              let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData)
        else {
            return .blue
        }
        return Color(uiColor: uiColor)
    }
}
