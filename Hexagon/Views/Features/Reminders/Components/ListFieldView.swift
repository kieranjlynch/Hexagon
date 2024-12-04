//
//  ListFieldView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI

struct ListFieldView: View {
    @Binding var selectedList: TaskList?
    var colorScheme: ColorScheme
    @EnvironmentObject private var listService: ListService
    @State private var lists: [TaskList] = []
    
    var body: some View {
        Menu {
            Button {
                selectedList = nil
            } label: {
                if selectedList == nil {
                    Label("None", systemImage: "checkmark")
                } else {
                    Text("None")
                }
            }
            
            ForEach(lists, id: \.self) { list in
                Button {
                    selectedList = list
                } label: {
                    if selectedList == list {
                        Label(list.name ?? "", systemImage: "checkmark")
                    } else {
                        Text(list.name ?? "")
                    }
                }
            }
        } label: {
            Text(selectedList?.name ?? "None")
                .foregroundColor(.blue)
        }
        .onAppear {
            Task {
                do {
                    lists = try await listService.fetchAllLists()
                } catch {
                    print("Error fetching lists: \(error)")
                }
            }
        }
    }
}
