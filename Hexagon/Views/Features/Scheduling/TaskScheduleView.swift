//
//  TaskScheduleView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI


struct TaskScheduleView: View {
    let task: String
    @State private var selectedDate = Date()
    @State private var selectedDuration: Double = 60
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date and Time")) {
                    DatePicker(
                        "Start Time",
                        selection: $selectedDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                Section(header: Text("Duration")) {
                    Slider(
                        value: $selectedDuration,
                        in: 15...240,
                        step: 15
                    ) {
                        Text("Duration")
                    } minimumValueLabel: {
                        Text("15m")
                    } maximumValueLabel: {
                        Text("4h")
                    }
                    Text("Duration: \(Int(selectedDuration)) minutes")
                }
            }
            .navigationTitle("Schedule Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schedule") {
                        scheduleTask()
                    }
                }
            }
        }
        .alert("Schedule Result", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("successfully") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func scheduleTask() {
        Task {
            do {
                try await CalendarService.shared.saveTaskToCalendar(
                    title: task,
                    startDate: selectedDate,
                    duration: selectedDuration
                )
                alertMessage = "Task scheduled successfully"
                showingAlert = true
            } catch CalendarService.CalendarError.accessDenied {
                alertMessage = "Calendar access denied. Please enable in Settings."
                showingAlert = true
            } catch {
                alertMessage = "Failed to schedule task: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
}
