//
//  LimitTasksInProgressView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 30/10/2024.
//

import SwiftUI

struct LimitTasksInProgressView: View {
    @AppStorage("maxTasksStartedPerDay") private var maxTasksStartedPerDay: Int = 3
    @AppStorage("maxTasksCompletedPerDay") private var maxTasksCompletedPerDay: Int = 5
    @AppStorage("isStartLimitUnlimited") private var isStartLimitUnlimited: Bool = false
    @AppStorage("isCompletionLimitUnlimited") private var isCompletionLimitUnlimited: Bool = false
    
    init() {
        UserDefaults.standard.register(defaults: [
            "isStartLimitUnlimited": true,
            "isCompletionLimitUnlimited": true
        ])
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Number of tasks which can be started on a date")
                        .font(.subheadline)
                        .padding(.bottom)
                    
                    if !isStartLimitUnlimited {
                        HStack {
                            Stepper(value: $maxTasksStartedPerDay, in: 1...20) {
                                Text("Tasks started limit: ")
                                + Text("\(maxTasksStartedPerDay)")
                                    .fontWeight(.bold)
                            }
                        }
                    } else {
                        Text("No Limit on Task Starts")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    
                    Toggle("Unlimited", isOn: $isStartLimitUnlimited)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .padding(.top)
                }
                .padding(.top)
                
                Divider()
                
                VStack(alignment: .leading) {
                    Text("Number of tasks which can be completed on a date")
                        .font(.subheadline)
                        .padding(.bottom)
                    
                    if !isCompletionLimitUnlimited {
                        HStack {
                            Stepper(value: $maxTasksCompletedPerDay, in: 1...20) {
                                Text("Tasks completed limit: ")
                                + Text("\(maxTasksCompletedPerDay)")
                                    .fontWeight(.bold)
                            }
                        }
                    } else {
                        Text("No Limit on Task Completions")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    
                    Toggle("Unlimited", isOn: $isCompletionLimitUnlimited)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .padding(.top)
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Limit Tasks In Progress")
            .onChange(of: isStartLimitUnlimited) { oldValue, newValue in
                if newValue {
                    maxTasksStartedPerDay = 3
                }
            }
            .onChange(of: isCompletionLimitUnlimited) { oldValue, newValue in
                if newValue {
                    maxTasksCompletedPerDay = 5
                }
            }
        }
    }
}
