//
//  AddNewListView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import HexagonData

struct AddNewListView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var reminderService: ReminderService
    @EnvironmentObject private var listService: ListService
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var selectedColor: Color
    @State private var selectedSymbol: String
    @State private var searchText: String = ""
    @State private var showSymbolPicker: Bool = false
    
    private var taskList: TaskList?
    
    init(taskList: TaskList? = nil) {
        self.taskList = taskList
        _name = State(initialValue: taskList?.name ?? "")
        _selectedColor = State(initialValue: taskList != nil ? Color(UIColor.color(data: taskList!.colorData ?? Data()) ?? .yellow) : .yellow)
        _selectedSymbol = State(initialValue: taskList?.symbol ?? "list.bullet")
    }
    
    private var isFormValid: Bool {
        !name.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(alignment: .center, spacing: 16) {
                    ListHeader(selectedSymbol: $selectedSymbol, selectedColor: $selectedColor, name: $name, colorScheme: colorScheme)
                        .frame(height: 50)
                    ColorPickerView(selectedColor: $selectedColor)
                        .frame(maxWidth: 200)
                }
                .padding()
                
                if showSymbolPicker {
                    VStack(spacing: 16) {
                        SearchBar(searchText: $searchText, colorScheme: colorScheme)
                        SymbolPickerView(selectedSymbol: $selectedSymbol, selectedColor: $selectedColor, searchText: $searchText)
                            .transition(.move(edge: .leading))
                    }
                    .animation(.easeInOut, value: showSymbolPicker)
                } else {
                    Button(action: {
                        withAnimation {
                            showSymbolPicker.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: selectedSymbol)
                                .foregroundColor(selectedColor)
                            Text("Choose Symbol")
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding([.horizontal, .vertical])
                }
                
                Spacer()
                
                ButtonRow(isFormValid: isFormValid, saveAction: saveList, dismissAction: { dismiss() }, colorScheme: colorScheme)
            }
            .padding(.horizontal)
            .navigationTitle(taskList == nil ? "Add List" : "Edit List")
            .navigationBarTitleDisplayMode(.inline)
            .background(backgroundView)
        }
    }
    
    private var backgroundView: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    private func saveList() async {
        let uiColor = UIColor(selectedColor)
        do {
            if let existingList = taskList {
                try await listService.updateTaskList(existingList, name: name, color: uiColor, symbol: selectedSymbol)
            } else {
                try await listService.saveTaskList(name: name, color: uiColor, symbol: selectedSymbol)
            }
            dismiss()
        } catch {
            return
        }
    }
    
    struct ListHeader: View {
        @Binding var selectedSymbol: String
        @Binding var selectedColor: Color
        @Binding var name: String
        var colorScheme: ColorScheme
        
        var body: some View {
            HStack {
                Image(systemName: selectedSymbol)
                    .foregroundColor(selectedColor)
                    .font(.system(size: 30))
                    .frame(width: 40, height: 40)
                TextField("List Name", text: $name)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
    
    struct SearchBar: View {
        @Binding var searchText: String
        var colorScheme: ColorScheme
        
        var body: some View {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search icons", text: $searchText)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            }
            .padding(8)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
            .padding(.bottom, 8)
        }
    }
    
    struct ButtonRow: View {
        let isFormValid: Bool
        let saveAction: () async -> Void
        let dismissAction: () -> Void
        var colorScheme: ColorScheme
        
        var body: some View {
            HStack {
                CustomButton(title: "Cancel", action: dismissAction, style: .secondary)
                
                CustomButton(title: "Save", action: {
                    Task {
                        await saveAction()
                    }
                }, style: .primary)
                .disabled(!isFormValid)
            }
            .padding()
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
    }
}
