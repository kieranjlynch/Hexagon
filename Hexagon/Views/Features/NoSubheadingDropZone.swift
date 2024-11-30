//
//  NoSubheadingDropZone.swift
//  Hexagon
//
//  Created by Kieran Lynch on 25/11/2024.
//

import SwiftUI

import UniformTypeIdentifiers

struct NoSubheadingDropZone: View {
    @Binding var isTargeted: Bool
    let dragStateManager: DragStateManager
    let viewModel: ListDetailViewModel
    
    var body: some View {
        VStack {
        }
        .frame(maxWidth: .infinity)
        .onDrop(
            of: [.hexagonListItem],
            isTargeted: Binding(
                get: { isTargeted },
                set: { isTargeted = $0 }
            )
        ) { providers, _ in
            guard let item = dragStateManager.draggingListItem else { return false }
            
            viewModel.moveItem(item, toIndex: Int.max, underSubHeading: nil)
            dragStateManager.endDragging()
            return true
        }
    }
}
