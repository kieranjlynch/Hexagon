//
//  RepeatFieldView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 08/11/2024.
//

import SwiftUI

import CoreData

struct RepeatFieldView: View {
    @Binding var repeatOption: RepeatOption
    @Binding var customRepeatInterval: Int
    let colorScheme: ColorScheme
    @State private var showRepeatOptionsSheet = false
    
    var body: some View {
        Button(action: {
            showRepeatOptionsSheet = true
        }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.primary)
                
                Text("Repeat")
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(repeatOption.rawValue)
                    .foregroundColor(.red)
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showRepeatOptionsSheet) {
            RepeatOptionsView(repeatOption: $repeatOption, customRepeatInterval: $customRepeatInterval)
        }
        .listRowBackground(colorScheme == .dark ? Color.black : Color.white)
        .padding(.horizontal)
    }
}

struct RepeatOptionsView: View {
    @Binding var repeatOption: RepeatOption
    @Binding var customRepeatInterval: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(RepeatOption.allCases, id: \.self) { option in
                    Button(action: {
                        repeatOption = option
                        if option != .custom {
                            dismiss()
                        }
                    }) {
                        HStack {
                            Text(option.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if repeatOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                if repeatOption == .custom {
                    Stepper("Every \(customRepeatInterval) days", value: $customRepeatInterval, in: 1...365)
                }
            }
            .navigationTitle("Repeat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
