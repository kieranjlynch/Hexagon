import SwiftUI


struct AddNewListView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fetchingService: ReminderFetchingServiceUI
    @EnvironmentObject private var listService: ListService
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var selectedColor: Color
    @State private var selectedSymbol: String
    @State private var searchText: String = ""
    @State private var errorMessage: String?
    
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
                    ListHeader(selectedSymbol: $selectedSymbol, selectedColor: $selectedColor, name: $name, colorScheme: _colorScheme)
                        .frame(height: 50)
                    ColorPickerView(selectedColor: $selectedColor)
                        .frame(maxWidth: 200)
                }
                .padding()
                
                VStack(spacing: 16) {
                    SearchBar(text: $searchText, placeholder: "Search icons")
                    SymbolPickerView(selectedSymbol: $selectedSymbol, selectedColor: $selectedColor, searchText: $searchText)
                        .frame(maxHeight: 300)
                }
                
                Spacer()
                
                ButtonRowView(
                    isFormValid: isFormValid,
                    saveAction: { await saveList() },
                    dismissAction: { dismiss() },
                    colorScheme: colorScheme
                )
            }
            .padding(.horizontal)
            .navigationTitle(taskList == nil ? "Add List" : "Edit List")
            .navigationBarTitleDisplayMode(.inline)
            .background(backgroundView)
            .alert(isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "An unknown error occurred."),
                    dismissButton: .default(Text("OK"))
                )
            }
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
                let _ = try await listService.saveTaskList(name: name, color: uiColor, symbol: selectedSymbol)
            }
            dismiss()
        } catch let error as ListService.ListServiceError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


struct ListHeader: View {
    @Binding var selectedSymbol: String
    @Binding var selectedColor: Color
    @Binding var name: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: selectedSymbol)
                .foregroundColor(selectedColor)
                .font(.system(size: 30))
                .frame(width: 40, height: 40)
            TitleTextField(text: $name)
                .textFieldStyle(.roundedBorder)
        }
    }
}
