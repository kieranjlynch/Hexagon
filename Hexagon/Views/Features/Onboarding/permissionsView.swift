//
//  PermissionsView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 07/09/2024.
//

import SwiftUI
import CoreLocation
import Intents
import Photos
import EventKit
import AVFoundation
import HexagonData

struct PermissionsView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var locationService = LocationService()
    @State private var locationPermission = false
    @State private var siriPermission = false
    @State private var photosPermission = false
    @State private var calendarPermission = false
    @State private var microphonePermission = false
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    @State private var eventStore = EKEventStore()
    
    let onContinue: () -> Void
    let isInSettings: Bool
    
    var body: some View {
        VStack {
            Text("Permissions")
                .font(.largeTitle)
                .bold()
                .padding()
                .adaptiveForegroundAndBackground()
            
            Text("Hexagon needs your permission to access your data. It always stays private.")
                .padding()
                .font(.body)
                .adaptiveForegroundAndBackground()
            
            VStack(spacing: 30) {
                permissionRow(
                    icon: "location.circle.fill",
                    label: "Location",
                    color: .green,
                    isOn: $locationPermission
                )
                .onChange(of: locationPermission) { _, newValue in
                    handleLocationToggle(newValue)
                }
                
                permissionRow(
                    icon: "waveform.circle.fill",
                    label: "Siri",
                    color: .purple,
                    isOn: $siriPermission
                )
                .onChange(of: siriPermission) { _, newValue in
                    handleSiriToggle()
                }
                
                permissionRow(
                    icon: "photo.circle.fill",
                    label: "Photos",
                    color: .blue,
                    isOn: $photosPermission
                )
                .onChange(of: photosPermission) { _, newValue in
                    handlePhotosToggle()
                }
                
                permissionRow(
                    icon: "calendar.circle.fill",
                    label: "Calendar",
                    color: .red,
                    isOn: $calendarPermission
                )
                .onChange(of: calendarPermission) { _, newValue in
                    handleCalendarToggle()
                }
                
                permissionRow(
                    icon: "mic.circle.fill",
                    label: "Microphone",
                    color: .orange,
                    isOn: $microphonePermission
                )
                .onChange(of: microphonePermission) { _, newValue in
                    handleMicrophoneToggle(newValue)
                }
            }
            .padding()
            
            Spacer()
            
            if !isInSettings {
                CustomButton(title: "Continue", action: onContinue, style: .primary)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .padding()
        .adaptiveForegroundAndBackground()
        .onAppear {
            checkLocationPermission()
        }
    }
    
    private func handleLocationToggle(_ newValue: Bool) {
        if newValue {
            locationService.requestWhenInUseAuthorization()
        } else {
            openSettings()
        }
    }
    
    private func checkLocationPermission() {
        locationPermission = locationService.authorizationStatus == .authorizedWhenInUse ||
        locationService.authorizationStatus == .authorizedAlways
    }
    
    private func handleSiriToggle() {
        if siriPermission {
            requestSiriPermission()
        } else {
            openSettings()
        }
    }
    
    private func handleMicrophoneToggle(_ newValue: Bool) {
        if newValue {
            requestMicrophonePermission()
        } else {
            openSettings()
        }
    }
    
    private func requestMicrophonePermission() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.microphonePermission = granted
                if !granted {
                    self.openSettings()
                }
            }
        }
    }
    
    private func requestSiriPermission() {
        INPreferences.requestSiriAuthorization { status in
            DispatchQueue.main.async {
                self.siriPermission = (status == .authorized)
                if status == .denied {
                    self.openSettings()
                }
            }
        }
    }
    
    private func handlePhotosToggle() {
        if photosPermission {
            requestPhotosPermission()
        } else {
            openSettings()
        }
    }
    
    private func requestPhotosPermission() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                self.photosPermission = (status == .authorized)
                if status == .denied || status == .restricted {
                    self.openSettings()
                }
            }
        }
    }
    
    private func handleCalendarToggle() {
        if calendarPermission {
            requestCalendarPermission()
        } else {
            openSettings()
        }
    }
    
    private func requestCalendarPermission() {
        eventStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                self.calendarPermission = granted
                if !granted {
                    self.openSettings()
                }
            }
        }
    }
    
    private func openSettings() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings)
        }
    }
}
