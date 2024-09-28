//
//  RemindersListView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

//import SwiftUI
//
//struct RemindersListView: View {
//    @Environment(\.colorScheme) var colorScheme
//    @EnvironmentObject private var reminderService: ReminderService
//    let reminders: [Reminder]
//    let onTap: (Reminder) -> Void
//    let onToggleCompletion: (Reminder) -> Void
//    
//    @Environment(\.managedObjectContext) private var viewContext
//    
//    var body: some View {
//        ForEach(reminders) { reminder in
//            TaskCardView(
//                reminder: reminder,
//                onTap: {
//                    onTap(reminder)
//                },
//                onToggleCompletion: {
//                    onToggleCompletion(reminder)
//                },
//                selectedDate: Date(),
//                selectedDuration: 60.0
//            )
//            .listRowBackground(Color(colorScheme == .dark ? .black : .white))
//        }
//    }
//}
