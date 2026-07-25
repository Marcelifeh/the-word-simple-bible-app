import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var notificationSettingsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    UNUserNotificationCenter.current().delegate = self
    if let controller = window?.rootViewController as? FlutterViewController {
      notificationSettingsChannel = FlutterMethodChannel(
        name: "the_word/notification_settings",
        binaryMessenger: controller.binaryMessenger
      )
      notificationSettingsChannel?.setMethodCallHandler { call, result in
        guard call.method == "openNotificationSettings" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
          result(
            FlutterError(
              code: "settings_unavailable",
              message: "Notification settings are unavailable.",
              details: nil
            )
          )
          return
        }
        UIApplication.shared.open(url)
        result(nil)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
