//
//  WebAppWrapperApp.swift
//  WebAppWrapper
//
//  Created by CB on 19/1/2025.
//

import SwiftUI
import FirebaseCore

@main
struct WebAppWrapperApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            LaunchView()
                .onOpenURL { url in
                    // App opened by universal links
                    print("Open url \(url)")
                    AppState.shared.handleUniversalLink(url)
                }
        }
    }
}

// Show an animated page when loading the webview
struct LaunchView: View {
    @State private var isLoading = true
    @State private var logoScale: CGFloat = 1.0
    @State private var logoOpacity: Double = 1.0
    var body: some View {
        ZStack {
            if isLoading {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack {
                    Image("app-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                    
                    Text("Let's wrap your web app!")
                        .foregroundStyle(.white)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .animation(.easeInOut(duration: 0.5), value: logoScale)
                .animation(.easeInOut(duration: 0.5), value: logoOpacity)
                .transition(.asymmetric(insertion: .scale, removal: .opacity))
            }
            LaunchPage()
                .opacity(isLoading ? 0 : 1)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    logoScale = 7.0
                    logoOpacity = 0.2
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isLoading = false
                    }
                }
            }
        }
    }
}
