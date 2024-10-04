//
//  ListFieldView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import SwiftUI
import HexagonData

struct ListFieldView: View {
    @Binding var selectedList: TaskList?
    var colorScheme: ColorScheme
    @EnvironmentObject private var listService: ListService
    
    var body: some View {
        HStack {
            NavigationLink {
                ListSheetView(selectedList: $selectedList, listService: listService)
            } label: {
                Label {
                    Text("List")
                } icon: {
                    Image(systemName: "list.bullet")
                }
                .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            Spacer()
            if let selectedList = selectedList {
                Text(selectedList.name ?? "")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.UI.cornerRadius)
            }
        }
    }
}
