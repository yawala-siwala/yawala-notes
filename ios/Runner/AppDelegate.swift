import Flutter
import UIKit

/// Yawala Notes - iOS runner bootstrap.
///
/// Registers the `com.yawalasiwala/notes` method channel so the Dart layer
/// can drive UIDocumentPicker export/import and native markdown rendering
/// (NSAttributedString bridges). Values below are safe-fallback stubs until
/// the real document-picker integration lands.
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.yawalasiwala/notes",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
        case "exportNote", "importNoteFile":
          result(nil)
        case "renderMarkdown":
          result(["html": "<p>stub</p>", "usedNativeRenderer": false])
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
