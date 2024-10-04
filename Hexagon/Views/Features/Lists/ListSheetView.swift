//
//  ListSheetView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import HexagonData

public struct ListSheetView: View {
    @Environment(\.appTintColor) var appTintColor
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedList: TaskList?
    @State private var lists: [TaskList] = []
    @State private var isShowingAddNewList = false
    @EnvironmentObject private var reminderService: ReminderService
    @State private var errorMessage: String?
    
    private let listService: ListService
    
    public init(selectedList: Binding<TaskList?>, listService: ListService) {
        self._selectedList = selectedList
        self.listService = listService
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Text("Save to a List")
                .font(.title2)
                .fontWeight(.bold)
                .adaptiveColors()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            
            List {
                listButton(for: nil, text: "No List")
                
                ForEach(lists, id: \.self) { list in
                    listButton(for: list, text: list.name ?? "")
                }
                
                addNewListButton
            }
            .listStyle(PlainListStyle())
            .listSettings()
        }
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $isShowingAddNewList) {
            AddNewListView()
        }
        .errorAlert(errorMessage: $errorMessage)
        .task {
            await fetchLists()
        }
        .onChange(of: isShowingAddNewList) { oldValue, newValue in
            if !newValue && oldValue {
                Task {
                    await fetchLists()
                }
            }
        }
    }
    
    private func listButton(for list: TaskList?, text: String) -> some View {
        standardListButton(
            text: text,
            isSelected: selectedList?.id == list?.id,
            appTintColor: appTintColor
        ) {
            selectedList = list
        }
    }
    
    private var addNewListButton: some View {
        Button(action: {
            isShowingAddNewList = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add New List")
            }
            .foregroundColor(appTintColor)
            .padding(.vertical, 8)
        }
    }
    
    private func fetchLists() async {
        do {
            lists = try await listService.updateTaskLists()
        } catch {
            errorMessage = "Failed to fetch lists: \(error.localizedDescription)"
        }
    }
}
