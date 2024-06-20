import SwiftUI

struct SymbolPickerView: View {
    @Binding var selectedSymbol: String
    @Binding var selectedColor: Color
    @Binding var searchText: String
    
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var filteredSymbols: [String] {
        if searchText.isEmpty {
            return SymbolsLoader.symbols
        } else {
            return SymbolsLoader.symbols.filter { $0.contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(filteredSymbols, id: \.self) { symbol in
                    Image(systemName: symbol)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .foregroundColor(selectedSymbol == symbol ? selectedColor : .offWhite)
                        .onTapGesture {
                            selectedSymbol = symbol
                        }
                }
            }
        }
    }
}
