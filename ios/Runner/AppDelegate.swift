import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let notificationChannelName = "collectiq_ai/notifications"

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Registering this channel in didFinishLaunchingWithOptions (the old
    // location) raced the implicit engine's own initialization: at that
    // point window?.rootViewController wasn't a FlutterViewController yet
    // (GeneratedPluginRegistrant registration above already waits for this
    // same callback for that exact reason), so the guard silently failed
    // and the channel was never registered at all -- every Dart-side call
    // hit MissingPluginException, which getPermissionStatus() maps to
    // .notSupported. Always showed "Alerts aren't available on this device
    // yet" in Settings regardless of the real OS permission state.
    registerNotificationChannel(messenger: engineBridge.applicationRegistrar.messenger())
  }

  private func registerNotificationChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: notificationChannelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "initialize":
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        result(nil)
      case "getPermissionStatus":
        self?.getNotificationPermissionStatus(result: result)
      case "requestPermission":
        self?.requestNotificationPermission(result: result)
      case "showPriceAlertNotification":
        self?.showPriceAlertNotification(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func getNotificationPermissionStatus(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      DispatchQueue.main.async {
        result(self.permissionStatusName(settings.authorizationStatus))
      }
    }
  }

  private func requestNotificationPermission(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { granted, _ in
      DispatchQueue.main.async {
        if granted {
          UIApplication.shared.registerForRemoteNotifications()
        }
        result(granted ? "granted" : "denied")
      }
    }
  }

  private func showPriceAlertNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      guard self.canShowNotifications(settings.authorizationStatus) else {
        DispatchQueue.main.async {
          result([
            "status": "permissionDenied",
            "message": "Notification permission is required.",
          ])
        }
        return
      }

      let arguments = call.arguments as? [String: Any]
      let id = arguments?["id"] as? Int ?? Int.random(in: 1...Int.max)
      let title = arguments?["title"] as? String ?? "Price alert triggered"
      let body = arguments?["body"] as? String ?? "A collectible price alert triggered."

      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = .default

      let request = UNNotificationRequest(
        identifier: "price-alert-\(id)",
        content: content,
        trigger: nil
      )
      UNUserNotificationCenter.current().add(request) { error in
        DispatchQueue.main.async {
          if let error {
            result([
              "status": "failed",
              "message": error.localizedDescription,
            ])
          } else {
            result([
              "status": "delivered",
              "message": body,
            ])
          }
        }
      }
    }
  }

  private func permissionStatusName(_ status: UNAuthorizationStatus) -> String {
    if canShowNotifications(status) {
      return "granted"
    }
    switch status {
    case .denied:
      return "denied"
    case .notDetermined:
      return "unknown"
    @unknown default:
      return "unknown"
    }
  }

  private func canShowNotifications(_ status: UNAuthorizationStatus) -> Bool {
    if status == .authorized || status == .provisional {
      return true
    }
    if #available(iOS 14.0, *) {
      return status == .ephemeral
    }
    return false
  }
}
