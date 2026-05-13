import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let settingsChannel = FlutterMethodChannel(
      name: "com.in5km.gotobed/settings",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    settingsChannel.setMethodCallHandler { call, result in
      if call.method == "openNotificationSettings" {
        let urlString: String
        if #available(iOS 16.0, *) {
          urlString = UIApplication.openNotificationSettingsURLString
        } else {
          urlString = UIApplication.openSettingsURLString
        }
        if let url = URL(string: urlString) {
          UIApplication.shared.open(url)
        }
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
