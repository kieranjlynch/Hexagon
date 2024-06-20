import SwiftUI
import UIKit

struct AddNewListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var selectedColor: Color = .yellow
    @State private var selectedSymbol: String = "list.bullet"
    @State private var searchText: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    let onSave: (String, UIColor, String) -> Void
    
    private var isFormValid: Bool {
        !name.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image(systemName: selectedSymbol)
                        .foregroundColor(selectedColor)
                        .font(.system(size: 30))
                        .frame(width: 40, height: 40)
                    TextField("List Name", text: $name)
                        .foregroundColor(.darkGray)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                
                ColorPickerView(selectedColor: $selectedColor)
                    .padding(.top, 0)
                    .padding(.bottom, 0)
                
                Divider()
                
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search icons", text: $searchText)
                        .foregroundColor(.darkGray)
                }
                .padding(6)
                .background(Color.offWhite)
                .cornerRadius(8)
                .padding([.horizontal, .bottom])
                
                SymbolPickerView(selectedSymbol: $selectedSymbol, selectedColor: $selectedColor, searchText: $searchText)
                
                Spacer()
                
                HStack {
                    CancelButton(cancelAction: { presentationMode.wrappedValue.dismiss() })
                    SubmitButton(submitAction: {
                        onSave(name, UIColor(selectedColor), selectedSymbol)
                        presentationMode.wrappedValue.dismiss()
                    })
                }
                .padding()
                .background(Color.darkGray)
            }
            .navigationTitle("Add List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.darkGray, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .background(Color.darkGray.ignoresSafeArea())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
