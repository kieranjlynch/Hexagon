//
//  SettingsView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import StoreKit
import UniformTypeIdentifiers


struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @SceneStorage("SettingsView.selectedSection") private var selectedSection: String?
    @StateObject private var locationViewModel = LocationViewModel(
        locationService: LocationService.shared,
        searchService: MapSearchService.shared,
        permissionsHandler: LocationPermissionManager.shared
    )
    @State private var isExporting = false
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    settingsNavigationLink(
                        title: "Appearance",
                        iconName: "paintbrush",
                        iconColor: .blue
                    ) {
                        AppearanceSettingsView()
                    }
                    
                    settingsNavigationLink(
                        title: "Date Format",
                        iconName: "calendar",
                        iconColor: .orange
                    ) {
                        DateSettingsView()
                    }
                    
                    settingsNavigationLink(
                        title: "Permissions",
                        iconName: "lock.shield",
                        iconColor: .green
                    ) {
                        PermissionsView(onContinue: {}, isInSettings: true)
                    }
                    
                    settingsNavigationLink(
                        title: "Limit tasks in progress",
                        iconName: "list.bullet",
                        iconColor: .purple
                    ) {
                        LimitTasksInProgressView()
                    }
                    
                    settingsNavigationLink(
                        title: "Locations",
                        iconName: "map",
                        iconColor: .red
                    ) {
                        MapView(
                            viewModel: locationViewModel,
                            searchService: MapSearchService.shared
                        )
                    }
                    
                    Button(action: rateApp) {
                        HStack {
                            SettingsIconView(iconName: "star.fill", backgroundColor: .yellow)
                            Text("Rate Hexagon")
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Button(action: exportDataAsCSV) {
                        HStack {
                            SettingsIconView(iconName: "square.and.arrow.up", backgroundColor: .gray)
                            Text("Export Data")
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .fileExporter(
                isPresented: $isExporting,
                document: CSVDocument(url: exportURL),
                contentType: .commaSeparatedText,
                defaultFilename: "UserData"
            ) { result in
                if case .failure(_) = result {
                }
            }
        }
    }
    
    private func settingsNavigationLink<Destination: View>(
        title: String,
        iconName: String,
        iconColor: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            HStack {
                SettingsIconView(iconName: iconName, backgroundColor: iconColor)
                Text(title)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 8)
        }
    }
    
    private func rateApp() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            AppStore.requestReview(in: scene)
        }
    }
    
    private func exportDataAsCSV() {
        let csvString = "Name, Age, Email\nJohn Doe, 29, john.doe@example.com\nJane Smith, 34, jane.smith@example.com"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("UserData.csv")
        
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            exportURL = tempURL
            isExporting = true
        } catch {
        }
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var url: URL?
    
    init(url: URL?) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try FileWrapper(url: url)
    }
}

struct SettingsIconView: View {
    var iconName: String
    var backgroundColor: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .frame(width: 32, height: 32)
            Image(systemName: iconName)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
        }
    }
}
