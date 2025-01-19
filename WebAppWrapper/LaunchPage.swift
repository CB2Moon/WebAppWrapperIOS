//
//  LaunchPage.swift
//  WebAppWrapper
//
//  Created by CB on 19/1/2025.
//

import SwiftUI
import Combine

struct LaunchPage: View {
    @StateObject private var locationManager = LocationManager()
    @AppStorage(Constants.UserDefaults.loggedIn) private var isLoggedIn = false
    @State private var notificationURL: URL?
    @StateObject private var appState = AppState.shared
    @State private var cancellables = Set<AnyCancellable>()
    
    @State private var currentPage = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                Image("app-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                Text("Web App Wrapper")
                    .font(.caption)
                    .fontWeight(.bold)
                
                TabView(selection: $currentPage) {
                    ForEach(Array(Constants.slides.enumerated()), id: \.element.id) { index, slide in
                        VStack(spacing: 16) {
                            Image(slide.image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .padding()
                            
                            Text(slide.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            Text(slide.description)
                                .font(.subheadline)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 400)
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<Constants.slides.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.black : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                
                Spacer()
                
                Button("Let's Get Started") {
                    appState.showWebView = true
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                
                Spacer()
                
                VStack(spacing: 10) {
                    if !appState.isNotificationEnabled {
                        Button("Enable Notifications") {
                            openAppSettings()
                        }
                        .tint(.blue)
                    }
                    
                    if locationManager.authorizationStatus == .denied {
                        Button("Enable Location Services") {
                            openAppSettings()
                        }
                        .tint(.blue)
                    }
                }
                .padding()
            }
            .fullScreenCover(isPresented: $appState.showWebView){
                WebViewPage(isPresented: $appState.showWebView)
            }
        }
        .onAppear {
            locationManager.requestPermission()
            AppState.shared.$notificationURL
                .receive(on: DispatchQueue.main)
                .sink { url in
                    // show WebView when isLoggedIn
                    if isLoggedIn {
                        appState.showWebView = true
                    }
                }
                .store(in: &cancellables)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            appState.checkNotificationStatus()
        }
    }
    
    func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

#Preview {
    LaunchPage()
}
