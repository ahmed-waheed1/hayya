import Flutter
import UIKit
import UserNotifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets flutter_local_notifications show the adhan while the app is open.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate

    // Background adhan reschedule (docs/background-reschedule.md). The
    // identifier must match Info.plist and WorkmanagerBackgroundTasks in
    // Dart. With UIScene, plugins register after this method returns, too
    // late for BGTaskScheduler, so the launch handler is registered here.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "com.ahmedwaheed.hayya.adhanReschedule",
      // At most twice a day; iOS decides when it really runs.
      earliestBeginInSeconds: NSNumber(value: 12 * 60 * 60)
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
