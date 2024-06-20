import SwiftUI

struct SettingsView: View {
    @SceneStorage("SettingsView.selectedSection") private var selectedSection: String?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(value: "General") {
                        Text("General")
                    }
                    NavigationLink(value: "Appearance") {
                        Text("Appearance")
                    }
                    NavigationLink(value: "Layout") {
                        Text("Layout")
                    }
                    NavigationLink(value: "Dates and Times") {
                        Text("Dates and Times")
                    }
                    NavigationLink(value: "Notifications") {
                        Text("Notifications")
                    }
                }
                .listRowBackground(Color.darkGray)
                .foregroundColor(.offWhite)
                
                Section {
                    NavigationLink(value: "About") {
                        Text("About")
                    }
                    NavigationLink(value: "Help") {
                        Text("Help")
                    }
                }
                .listRowBackground(Color.darkGray)
                .foregroundColor(.offWhite)
                
                Section {
                    Button(action: {
                        // Handle import action
                    }) {
                        Text("Import")
                    }
                    
                    Button(action: {
                        // Handle export action
                    }) {
                        Text("Export")
                    }
                }
                .listRowBackground(Color.darkGray)
                
                Section {
                    Button(action: {
                        // Handle reset action
                    }) {
                        Text("Reset")
                            .foregroundColor(.red)
                    }
                }
                .listRowBackground(Color.darkGray)
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(Color.darkGray.ignoresSafeArea())
            .toolbarBackground(Color.darkGray, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: String.self) { value in
                switch value {
                case "General":
                    GeneralSettingsView()
                case "Appearance":
                    AppearanceSettingsView()
                case "Layout":
                    LayoutSettingsView()
                case "Dates and Times":
                    DateTimeSettingsView()
                case "Notifications":
                    NotificationSettingsView()
                case "About":
                    AboutView()
                case "Help":
                    HelpView()
                default:
                    EmptyView()
                }
            }
        }
    }
}
