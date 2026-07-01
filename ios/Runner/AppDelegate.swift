import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "br.com.domina.aresia/google_maps"
  private let defaultApiKey = "AIzaSyAItoYASbxcjaFVOrQ0zb6qgcS9z8i4o04"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey(defaultApiKey)
    GeneratedPluginRegistrant.register(with: self)
    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    setupGoogleMapsChannel()
    return didFinish
  }

  private func setupGoogleMapsChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "setApiKey" {
        guard
          let arguments = call.arguments as? [String: Any],
          let apiKey = arguments["apiKey"] as? String,
          !apiKey.isEmpty
        else {
          result(
            FlutterError(
              code: "INVALID_KEY",
              message: "API key is empty",
              details: nil
            )
          )
          return
        }
        GMSServices.provideAPIKey(apiKey)
        result(true)
        return
      }
      result(FlutterMethodNotImplemented)
    }
  }
}
