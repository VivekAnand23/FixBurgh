import Flutter
import GoogleMaps
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Key comes from ios/Flutter/Secrets.xcconfig. Without it the map shows
    // blank tiles instead of crashing.
    let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String ?? ""
    GMSServices.provideAPIKey(key.isEmpty ? "missing-key" : key)
    // Sends reports saved offline (lib/app/background.dart). The ID must
    // match BGTaskSchedulerPermittedIdentifiers in Info.plist.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "com.fixburgh.outbox")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
