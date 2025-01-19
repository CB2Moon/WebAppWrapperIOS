//
//  AppState.swift
//  WebAppWrapper
//
//  Created by CB on 19/1/2025.
//

import Foundation
import Combine
import WebKit

class AppState: ObservableObject {
    static let shared = AppState()
    
    weak var webView: WKWebView?
    @Published var notificationURL: String?
    @Published var shouldLoadNotificationURL = false
    @Published var isNotificationEnabled = false
    @Published var showWebView = false

    private init() {
        checkNotificationStatus()
    }
    
    // Running javascript `window.notificationTapped` in WebView is only needed for Single Page Application that has internal routing functions
    func handleNotificationURL(_ urlString: String?) {
        self.notificationURL = urlString
        
        guard let urlString = urlString else { return }
        
        if let webView = webView {
            let js = "if (typeof window.notificationTapped === 'function') { window.notificationTapped('\(urlString)'); }"
            DispatchQueue.main.async {
                webView.evaluateJavaScript(js)
            }
        } else {
            print("Setting shouldLoadNotificationURL to true")
            self.showWebView = true
            self.shouldLoadNotificationURL = true
        }
    }
    
    func resetNotification() {
        self.shouldLoadNotificationURL = false
        self.notificationURL = nil
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // Only handle specific links 
    func handleUniversalLink(_ url: URL) {
        if url.path.contains("/reset-password") || url.path.contains("/forgot-password") || url.path.contains("verify-email") {
            self.handleNotificationURL(url.absoluteString)
        }
    }
}
