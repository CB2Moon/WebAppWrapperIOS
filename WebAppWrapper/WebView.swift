//
//  WebView.swift
//  WebAppWrapper
//
//  Created by CB on 19/1/2025.
//

import SwiftUI
import WebKit
import Combine

struct WebView: UIViewRepresentable {
    let url: String
    @Binding var clearCache: Bool
    @Binding var isLoading: Bool
    let onLogout: () -> Void
    let onDismiss: () -> Void
    
    @StateObject private var appState = AppState.shared
    @StateObject private var locationManager = LocationManager()
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let controller = WKUserContentController()
        
        controller.add(context.coordinator, name: Constants.Controller.webInterface)
        controller.add(context.coordinator, name: Constants.Controller.locationInterface)
        
        configuration.userContentController = controller
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        AppState.shared.webView = webView
        
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        let urlToLoad = appState.shouldLoadNotificationURL
            ? URL(string: appState.notificationURL ?? url)!
            : URL(string: url)!
        
        var request = URLRequest(url: urlToLoad)
        
        // Optional setting to load the web app from cache or remote based on the version got at AppDelegate @fetchWebAppVersion
        if !UserDefaults.standard.bool(forKey: Constants.UserDefaults.shouldLoadWebAppFromCache) {
            print("Loading latest...")
            request.cachePolicy = .reloadIgnoringLocalCacheData
        }
        
        webView.load(request)
        
        if appState.shouldLoadNotificationURL {
            DispatchQueue.main.async {
                appState.resetNotification()
            }
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if clearCache {
            clearWebViewCache(webView)
            DispatchQueue.main.async {
                self.clearCache = false
            }
        }
    }
    
    private func clearWebViewCache(_ webView: WKWebView) {
        WKWebsiteDataStore.default().removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: Date(timeIntervalSince1970: 0)
        ) {
            //            webView.load(URLRequest(url: url))
            print("Cache cleared")
        }
    }
    private func clearWebViewCache() {
        WKWebsiteDataStore.default().removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: Date(timeIntervalSince1970: 0)
        ) {
            print("Cache cleared")
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
            parent.isLoading = false
            parent.onDismiss()
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            guard let urlString = webView.url?.absoluteString else { return }
            
            if urlString.hasSuffix("/login") {
                if let token = UserDefaults.standard.string(forKey: Constants.UserDefaults.deviceToken) {
                    let js = """
                        (function() {
                            var input = document.querySelector('input[name="deviceToken"]');
                            if (input) input.value = '\(token)';
                        })();
                    """
                    webView.evaluateJavaScript(js)
                }
            }
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == Constants.Controller.webInterface,
               let messageBody = message.body as? String {
                switch messageBody {
                case "loggedin":
                    UserDefaults.standard.set(true, forKey: Constants.UserDefaults.loggedIn)
                case "logout":
                    parent.clearWebViewCache()
                    parent.onLogout()
                default:
                    break
                }
            }
            if message.name == Constants.Controller.locationInterface,
               let messageBody = message.body as? String {
                switch messageBody {
                case "start":
                    parent.locationManager.startMonitoringLocation()
                case "single":
                    parent.locationManager.requestSingleLocation()
                case "stop":
                    parent.locationManager.stopMonitoringLocation()
                default:
                    break
                }
            }
        }
    }
}
