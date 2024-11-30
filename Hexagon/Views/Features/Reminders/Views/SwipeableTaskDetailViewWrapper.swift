//
//  SwipeableTaskDetailViewWrapper.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI

import CoreData

struct SwipeableTaskDetailViewWrapper: View {
    @Binding var reminders: [Reminder]
    @Binding var currentIndex: Int
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var fetchingService: ReminderFetchingServiceUI
    @EnvironmentObject var modificationService: ReminderModificationService
    @Environment(\.managedObjectContext) var context: NSManagedObjectContext
    
    var body: some View {
        Group {
            if !reminders.isEmpty {
                SwipeableTaskDetailView(
                    reminders: reminders,
                    currentIndex: $currentIndex
                )
            } else {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.title)
                                .padding()
                        }
                    }
                    Spacer()
                    Text("No reminders available")
                    Spacer()
                }
            }
        }
    }
}
