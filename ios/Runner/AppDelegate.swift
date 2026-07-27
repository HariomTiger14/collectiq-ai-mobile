import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let notificationChannelName = "collectiq_ai/notifications"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    registerNotificationChannel()
    return launched
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func registerNotificationChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: notificationChannelName,
      binaryMessenger: controller.binaryMessenger
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
