//
//  Constants.swift
//  WebAppWrapper
//
//  Created by CB on 19/1/2025.
//

import Foundation

struct Constants {
    struct UserDefaults {
        static let loggedIn = "LoggedIn"
        static let deviceToken = "DeviceToken"
        static let notificationURL = "NotificationURL"
        static let webAppVersion = "WebAppVersion"
        static let shouldLoadWebAppFromCache = "shouldLoadWebAppFromCache"
    }
    
    struct URL {
        static let login = "https://google.com"
        static let version = ""
//        static let login = "http://localhost/root"
//        static let version = "http://localhost/version.json"
    }
    
    struct Controller {
        static let webInterface = "iOSAppInterface"
        static let locationInterface = "iOSLocationInterface"
    }
    
    struct SlideItem: Identifiable {
        let id = UUID()
        let image: String
        let title: String
        let description: String
    }
    
    static let slides = [
        SlideItem(
            image: "step-1",
            title: "Step 1",
            description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
        ),
        SlideItem(
            image: "step-2",
            title: "Step 2",
            description: " Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur."
        ),
        SlideItem(
            image: "step-3",
            title: "Step 3",
            description: " Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum"
        ),
    ]
}
