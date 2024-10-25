//
//  SubheadingHeader.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI
import HexagonData
import DragAndDrop

struct SubheadingHeader: View {
    let subHeading: SubHeading
    @ObservedObject var viewModel: ListDetailViewModel

    var body: some View {
        HStack {
            Text(subHeading.title ?? "")
                .font(.headline)
            Spacer()
            // Additional buttons or actions
        }
        .dragable()
    }
}
