# WebAppWrapper for iOS

A simple wrapper for web app with
- Launch page
- Introduction slides
- Full-screen WebView
- Firebase notification
- app (universal) links
- location services (get current location, monitor location update in background, etc.)

## Additional settings
- Uncomment `FirebaseApp.configure()` and `Messaging.messaging().delegate = self` when your "GoogleService-Info.plist" is in place.
- For universal links, refer to Apple's [docs](https://developer.apple.com/documentation/xcode/supporting-associated-domains)

## Demo
<div style="display: flex; justify-content: space-around; gap: 3px; font-size: x-small;">
  <div style="text-align: center;">
      <img src="./demo/demo1.png" alt="Launch Screen" style="width: 100px; height: auto;">
      <p>Launch Screen</p>
  </div>
  <div style="text-align: center;">
      <img src="./demo/demo2.png" alt="Introduction slides" style="width: 100px; height: auto;">
      <p>Introduction slides</p>
  </div>
  <div style="text-align: center;">
      <img src="./demo/demo3.png" alt="Loading WebView" style="width: 100px; height: auto;">
      <p>Loading WebView</p>
  </div>
  <div style="text-align: center;">
      <img src="./demo/demo4.png" alt="Full-screen WebView" style="width: 100px; height: auto;">
      <p>Full-screen WebView</p>
  </div>
</div>
