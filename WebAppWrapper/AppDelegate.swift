//
//  AppDelegate.swift
//  WebAppWrapper
//
//  Created by CB on 19/1/2025.
//

import Foundation
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import Combine

//class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    private var cancellables = Set<AnyCancellable>()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // firebase & notification setup
//        FirebaseApp.configure()
        
//        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    
                    AppState.shared.checkNotificationStatus()
                }
            }
        }
        fetchWebAppVersion()
        
        return true
    }
    
    // used to determine whether to load the web app from fresh or from cache
    private func fetchWebAppVersion() {
        guard let url = URL(string: Constants.URL.version) else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map{ $0.data }  // ignore headers, get response data only
            .decode(type: WebAppVersionResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)  // subsequent operations to perform on the main thread
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("Version fetch error: \(error)")
                default:
                    break
                }
            }, receiveValue: { response in
                let currentStoredVersion = UserDefaults.standard.string(forKey: Constants.UserDefaults.webAppVersion)
                
                print("Fetched version: \(response.version)")
                print("Stored version: \(String(describing: currentStoredVersion))")
                
                if response.version == currentStoredVersion {
                    UserDefaults.standard.set(true, forKey: Constants.UserDefaults.shouldLoadWebAppFromCache)
                } else {
                    print("New app version!")
                    UserDefaults.standard.set(response.version, forKey: Constants.UserDefaults.webAppVersion)
                    UserDefaults.standard.set(false, forKey: Constants.UserDefaults.shouldLoadWebAppFromCache)
                }
            })
            .store(in: &cancellables)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().setAPNSToken(deviceToken, type: .unknown)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        
        UserDefaults.standard.set(fcmToken, forKey: Constants.UserDefaults.deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        print("Failed to register for remote noti: \(error.localizedDescription)")
    }
    
    // called for silent notifications or when the app processes notifications in background
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(.newData)
    }
    
    // called when the app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    // called when user taps the notification; should adjust to the data included in the notification sent from your backend
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        if let aps = userInfo["aps"] as? [String: Any],
           let urlString = aps["url"] as? String {
            AppState.shared.handleNotificationURL(urlString)
        }
        completionHandler()
    }
    
    // called when the app is triggered by universal link; additional settings are required, see https://developer.apple.com/documentation/xcode/supporting-associated-domains
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([any UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL{
            AppState.shared.handleUniversalLink(url)
            return true
        }
        return false
    }
}

struct WebAppVersionResponse: Codable {
    let version: String
}
