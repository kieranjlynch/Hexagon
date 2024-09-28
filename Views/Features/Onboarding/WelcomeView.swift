//
//  WelcomeView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 08/09/2024.
//

import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    @State private var onboardingStep: Int = 0
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var errorMessage: String? = nil
    @State private var isErrorPresented: Bool = false
    
    private let backgroundColor = Color(hex: "1B1B1E")
    
    var body: some View {
        ZStack {
            backgroundColor
                .adaptiveForegroundAndBackground()
                .ignoresSafeArea()
            
            switch onboardingStep {
            case 0:
                welcomeScreen
            case 1:
                PermissionsView(onContinue: {
                    onboardingStep = 2
                }, isInSettings: false)
            case 2:
                TaskTermSelectionView {
                    onboardingStep = 3
                }
            case 3:
                ContentView(selectedTab: .constant("Lists"))
                    .onAppear {
                        hasLaunchedBefore = true
                    }
            default:
                Text("Error: Invalid onboarding step")
                    .onAppear {
                        errorMessage = "Invalid onboarding step"
                        isErrorPresented = true
                    }
            }
        }
        .errorAlert(errorMessage: $errorMessage, isPresented: $isErrorPresented) 
    }
    
    private var welcomeScreen: some View {
        VStack {
            Spacer()
            
            Image("AppLaunchIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .onAppear {
                    withAnimation(.easeOut(duration: 1.5)) {
                        logoScale = 1.0
                        logoOpacity = 1.0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            onboardingStep = 1
                        }
                    }
                }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }
}
