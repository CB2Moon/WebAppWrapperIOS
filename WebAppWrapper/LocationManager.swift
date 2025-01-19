//
//  LocationManager.swift
//  WebAppWrapper
//
//  Created by CB on 19/1/2025.
//

import SwiftUI
import CoreLocation

enum LocationError: Error {
    case permissionDenied
    case locationDisabled
    case accuracyTooLow
    case timeout
    case network
    case heading
    case unknown(Error?)
    
    var description: String {
        switch self {
        case .permissionDenied: return "PERMISSION_DENIED"
        case .locationDisabled: return "LOCATION_DISABLED"
        case .accuracyTooLow: return "ACCURACY_TOO_LOW"
        case .timeout: return "TIMEOUT"
        case .network: return "NETWORK_ERROR"
        case .heading: return "HEADING_ERROR"
        case .unknown: return "UNKNOWN_ERROR"
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var currentHeading: CLLocationDirection?
    private var locationTimeout: Timer?
    private let timeoutInterval: TimeInterval = 10
    
    private var pendingStart = false
    private var singleLocationRequest = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.activityType = .otherNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        // Heading (direction) update
        locationManager.headingFilter = 5  // update changes by 5 degree
        locationManager.headingOrientation = .portrait
        
        NotificationCenter.default.addObserver(self, selector: #selector(batteryStateDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    @objc private func batteryStateDidChange(notification: Notification) {
        let batteryState = UIDevice.current.batteryState
        if batteryState != .charging && batteryState != .full {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        } else {
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func requestSingleLocation() {
        startMonitoringLocation(true)
    }
    
    func startMonitoringLocation(_ isSingleLocation: Bool = false) {
        pendingStart = true
        singleLocationRequest = isSingleLocation
        
        if locationManager.authorizationStatus == .notDetermined {
            requestPermission()
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let servicesEnabled = CLLocationManager.locationServicesEnabled()
            
            DispatchQueue.main.async {
                self.handleAuthorizationStatus(self.locationManager.authorizationStatus, servicesEnabled: servicesEnabled)
            }
        }
    }
    
    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus, servicesEnabled: Bool = true) {
        guard pendingStart else { return }
        
        switch status {
        case .restricted, .denied:
            sendErrorToWebView(.permissionDenied)
            pendingStart = false
        case .authorizedWhenInUse, .authorizedAlways:
            if servicesEnabled {
                startLocationUpdates()
            } else {
                sendErrorToWebView(.locationDisabled)
            }
            pendingStart = false
        case .notDetermined:
            // Wait for authorization response
            break
        @unknown default:
            sendErrorToWebView(.unknown(nil))
            pendingStart = false
        }
    }
    
    private func startLocationUpdates() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        // Set timeout
        locationTimeout = Timer.scheduledTimer(withTimeInterval: timeoutInterval, repeats: false) { [weak self] _ in
            self?.handleLocationTimeout()
        }
    }
    
    private func handleLocationTimeout() {
        sendErrorToWebView(.timeout)
        stopMonitoringLocation()
        // TODO send message to react to restart location listenning
    }
    
    func stopMonitoringLocation() {
        locationTimeout?.invalidate()
        locationTimeout = nil
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    private func sendErrorToWebView(_ error: LocationError) {
        guard let webView = AppState.shared.webView else { return }
        
        let errorMessage = error.description
        print("Sending location error: \(errorMessage)")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let js = """
            if (typeof window.onLocationError === 'function') {
                console.log('\(errorMessage)');
                window.onLocationError('\(errorMessage)', {
                    timestamp: \(Date().timeIntervalSince1970 * 1000)
                });
            }
            """
            
            DispatchQueue.main.async {
                webView.evaluateJavaScript(js) { (result, error) in
                    if let error = error {
                        print("Error sending error to WebView: \(error)")
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationTimeout?.invalidate()
        locationTimeout = nil
        
        guard let location = locations.last,
              let webView = AppState.shared.webView,
              location.timestamp.timeIntervalSinceNow > -5  // only process recent location
        else { return }
        
        // Check for accuracy
        if location.horizontalAccuracy > 100 { // 100 meters threshold
            sendErrorToWebView(.accuracyTooLow)
//            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let js = """
            if (typeof window.sendLocationUpdate === 'function') {
                window.sendLocationUpdate({
                    latitude: \(location.coordinate.latitude),
                    longitude: \(location.coordinate.longitude),
                    heading: \(self.currentHeading ?? -1),
                    timestamp: \(location.timestamp.timeIntervalSince1970 * 1000)
                });
            }
            """
            
            DispatchQueue.main.async {
                webView.evaluateJavaScript(js) { (result, error) in
                    if let error = error {
                        print("Error sending error to WebView: \(error)")
                    }
                    
                    if self.singleLocationRequest {
                        self.stopMonitoringLocation()
                        self.singleLocationRequest = false
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        
        guard let webView = AppState.shared.webView else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let js = """
            if (typeof window.sendLocationUpdate === 'function') {
                window.sendLocationUpdate({
                    heading: \(self.currentHeading ?? -1),
                    headingOnly: true
                });
            }
            """
            
            DispatchQueue.main.async {
                webView.evaluateJavaScript(js) { (result, error) in
                    if let error = error {
                        print("Error sending error to WebView: \(error)")
                    }
                }
            }
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError {
            switch error.code {
            case .denied:
                sendErrorToWebView(.permissionDenied)
            case .network:
                sendErrorToWebView(.network)
            case .headingFailure:
                sendErrorToWebView(.heading)
            case .locationUnknown:
                // Temporary error, might recover automatically
                print("Location unknown error: \(error.localizedDescription)")
//            case .rangingFailure:
//                sendErrorToWebView(.accuracyTooLow)
            case .regionMonitoringDenied:
                sendErrorToWebView(.permissionDenied)
            case .regionMonitoringFailure:
                sendErrorToWebView(.unknown(error))
            case .regionMonitoringSetupDelayed:
                // Temporary error, might recover automatically
                print("Region monitoring setup delayed: \(error.localizedDescription)")
            case .regionMonitoringResponseDelayed:
                // Temporary error, might recover automatically
                print("Region monitoring response delayed: \(error.localizedDescription)")
            default:
                print("Location manager error: \(error.localizedDescription)")
                sendErrorToWebView(.unknown(error))
            }
        } else {
            print("Non-CLError location error: \(error.localizedDescription)")
            sendErrorToWebView(.unknown(error))
        }
    }
    
    func requestPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let servicesEnabled = CLLocationManager.locationServicesEnabled()
            
            DispatchQueue.main.async {
                self.handleAuthorizationStatus(manager.authorizationStatus, servicesEnabled: servicesEnabled)
            }
        }
    }
}
