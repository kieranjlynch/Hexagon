//
//  View+Extensions.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import SwiftUI
import UniformTypeIdentifiers
import MapKit
import CoreLocation
import Foundation
import HexagonData

extension View {
    func newTagAlert(
        isShowingNewTagAlert: Binding<Bool>,
        newTagName: Binding<String>,
        addAction: @escaping () -> Void
    ) -> some View {
        self.alert("Add New Tag", isPresented: isShowingNewTagAlert) {
            TextField("Tag Name", text: newTagName)
            Button("Cancel", role: .cancel) { }
            Button("Add", action: addAction)
        } message: {
            Text("Enter a name for the new tag")
        }
    }
    
    func formattedDate(_ date: Date) -> String {
        return DateFormatter.sharedDateFormatter.string(from: date)
    }
    
    func errorAlert(errorMessage: Binding<String?>) -> some View {
        self.alert(isPresented: Binding<Bool>(
            get: { errorMessage.wrappedValue != nil },
            set: { if !$0 { errorMessage.wrappedValue = nil } }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage.wrappedValue ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    func navigationBarSetup(title: String) -> some View {
        self
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(UIColor.systemBackground), for: .navigationBar)
            .navigationTitle(title)
    }
    
    func adaptiveLabel(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.primary)
            Text(title)
                .foregroundColor(Color.primary)
        }
    }
    
    func sectionHeaderWithAction(icon: String, title: String, action: @escaping () -> Void) -> some View {
        HStack {
            adaptiveLabel(icon: icon, title: title)
            Spacer()
            Button(action: action) {
                Image(systemName: "plus.circle")
                    .foregroundColor(.blue)
            }
        }
    }
    
    func photoThumbnail(uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: Constants.UI.thumbnailHeight)
    }
    
    func standardBorderedTextEditor() -> some View {
        self
            .foregroundColor(Color.primary)
            .cornerRadius(Constants.UI.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius * 2)
                    .stroke(Color.gray, lineWidth: Constants.UI.borderWidth)
            )
            .padding()
    }
    
    func halfHeightOfContainer() -> some View {
        GeometryReader { geometry in
            self.frame(height: geometry.size.height / 2)
        }
    }
    
    func focusOnAppear(_ isFocused: FocusState<Bool>.Binding) -> some View {
        self.onAppear {
            DispatchQueue.main.async {
                isFocused.wrappedValue = true
            }
        }
    }
    
    func closeButton(action: @escaping () -> Void) -> some View {
        HStack {
            Spacer()
            Button(action: action) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(Color.primary)
                    .padding()
            }
        }
    }
    
    func mapView(currentLocation: CLLocationCoordinate2D?, selectedLocation: Binding<IdentifiableMapItem?>) -> some View {
        Group {
            if let currentLocation = currentLocation {
                Map(position: .constant(.region(MKCoordinateRegion(center: currentLocation, span: Constants.UI.mapSpan)))) {
                    UserAnnotation()
                    if let selectedLocation = selectedLocation.wrappedValue {
                        Annotation("Selected Location", coordinate: selectedLocation.mapItem.placemark.coordinate) {
                            LocationPin(coordinate: selectedLocation.mapItem.placemark.coordinate)
                        }
                    }
                }
            } else {
                Text(Constants.Strings.fetchingLocation)
            }
        }
        .frame(height: UIScreen.main.bounds.height * Constants.UI.mapHeight)
    }
    
    func standardListButton(
        text: String,
        isSelected: Bool,
        appTintColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .foregroundColor(Color.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(appTintColor)
                }
            }
        }
        .padding(.vertical, Constants.UI.buttonVerticalPadding)
    }
    
    func adaptiveSectionHeader(title: String) -> some View {
        Text(title)
            .foregroundColor(Color.primary)
            .font(.headline)
    }
    
    func listSettings() -> some View {
        self
            .listRowSeparator(.hidden)
            .scrollContentBackground(.hidden)
            .background(Color(UIColor.systemBackground))
    }
    
    func styledButton(title: String, style: CustomButtonStyle, appTintColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(style == .primary ? appTintColor : Color.gray.opacity(style == .primary ? 0.3 : 0.2))
                .foregroundColor(style == .primary ? .white : Color.primary)
                .cornerRadius(8)
        }
    }
    
    func adaptiveBackground() -> some View {
        self.background(Color(UIColor.systemBackground))
    }
    
    func adaptiveShadow() -> some View {
        self.shadow(color: Color.primary.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    func cardStyle() -> some View {
        self.cornerRadius(8)
            .adaptiveBackground()
            .adaptiveShadow()
    }
    
    func dateNavButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
        }
    }
    
    func taskIconView(systemName: String, label: String, hint: String, tintColor: Color) -> some View {
        Image(systemName: systemName)
            .foregroundColor(tintColor)
            .accessibilityLabel(label)
            .accessibilityHint(hint)
    }
    
    func completionToggleButton(isCompleted: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .frame(width: 24, height: 24)
                .padding(.leading, 8)
                .padding(.trailing, 12)
        }
        .accessibilityLabel(isCompleted ? "Mark as incomplete" : "Mark as complete")
        .accessibilityHint("Double-tap to toggle completion status")
    }
    
    func adaptiveForegroundAndBackground() -> some View {
        self
            .foregroundColor(Color.primary)
            .background(Color(UIColor.systemBackground))
    }
    
    func adaptiveSelectionColor(selected: Bool, selectedColor: Color) -> some View {
        self.foregroundColor(selected ? selectedColor : Color.primary)
    }
    
    func permissionRow(icon: String, label: String, color: Color, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title)
            Text(label)
                .font(.title2)
            Spacer()
            Toggle("", isOn: isOn)
        }
        .foregroundColor(Color.primary)
    }
    
    func adaptiveToolbarBackground() -> some View {
        self
            .toolbarBackground(Color(UIColor.systemBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    func adaptiveColors() -> some View {
        self.foregroundColor(Color.primary)
    }
    
    func errorAlert(errorMessage: Binding<String?>, isPresented: Binding<Bool>) -> some View {
        self.alert("Error", isPresented: isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage.wrappedValue ?? "An unknown error occurred")
        }
    }
}

struct ConsistentTaskListModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 16)
            .padding(.horizontal, Constants.UI.horizontalPadding)
    }
}

extension View {
    func consistentTaskListStyle() -> some View {
        self.modifier(ConsistentTaskListModifier())
    }
}

extension DateFormatter {
    static var sharedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        updateSharedDateFormatter(formatter: formatter)
        return formatter
    }()
    
    static func updateSharedDateFormatter() {
        updateSharedDateFormatter(formatter: sharedDateFormatter)
    }
    
    private static func updateSharedDateFormatter(formatter: DateFormatter) {
        let storedFormat = UserDefaults.standard.string(forKey: "dateFormat") ?? DateFormat.ddmmyy.rawValue
        formatter.dateFormat = storedFormat
    }
}

enum DateFormat: String, CaseIterable {
    case yymmdd = "yy/MM/dd"
    case ddmmyy = "dd/MM/yy"
    case mmddyy = "MM/dd/yy"
    case yyyymmdd = "yyyyMMdd"
    case ddmmyyyy = "dd/MM/yyyy"
    case mmddyyyy = "MM/dd/yyyy"
    case ddmmmyy = "dd MMM yy"
    case ddmmmyyyy = "dd MMM yyyy"
    
    var description: String {
        switch self {
        case .yymmdd:
            return "YY/MM/DD"
        case .ddmmyy:
            return "DD/MM/YY"
        case .mmddyy:
            return "MM/DD/YY"
        case .yyyymmdd:
            return "YYYYMMDD"
        case .ddmmyyyy:
            return "DD/MM/YYYY"
        case .mmddyyyy:
            return "MM/DD/YYYY"
        case .ddmmmyy:
            return "DD MMM YY"
        case .ddmmmyyyy:
            return "DD MMM YYYY"
        }
    }
}
