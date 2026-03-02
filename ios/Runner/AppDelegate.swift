import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Resolve UNUserNotificationCenter delegate conflict:
    // firebase_messaging overrides the delegate during plugin registration,
    // which prevents flutter_local_notifications from displaying foreground
    // notifications. Re-setting the delegate to self (FlutterAppDelegate)
    // ensures callbacks are forwarded to ALL notification plugins.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
  }
}
