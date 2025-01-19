//
//  WebViewPage.swift
//  WebAppWrapper
//
//  Created by CB on 19/1/2025.
//

import SwiftUI

struct WebViewPage: View {
    @Binding var isPresented: Bool
    @AppStorage(Constants.UserDefaults.loggedIn) private var isLoggedIn = false
    @State private var shouldClearCache = false
    @State private var isLoading = true
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        ZStack {
            WebView(url: Constants.URL.login,
                    clearCache: $shouldClearCache,
                    isLoading: $isLoading,
                    onLogout: {
                isLoggedIn = false
                isPresented = false
            }, onDismiss: {
                appState.resetNotification()
                isPresented = false
            })
            .ignoresSafeArea()
            .toolbar(.hidden)
            .transition(.asymmetric(insertion: .opacity, removal: .opacity))
            .animation(.easeInOut(duration: 2.5), value: isLoading)

            if isLoading {
                WebAppLoadingView()
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                    .animation(.easeInOut(duration: 2.5), value: isLoading)
            }
        }
    }
}
