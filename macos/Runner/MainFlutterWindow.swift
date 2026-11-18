import Cocoa
import FlutterMacOS

/// Yawala Notes - macOS runner bootstrap.
class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    registerNativeBindingStubs(with: flutterViewController)
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  /// Registers the `com.yawalasiwala/notes` method channel with safe-fallback
  /// responses until the real NSSavePanel / NSAttributedString bridges land.
  private func registerNativeBindingStubs(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.yawalasiwala/notes",
      binaryMessenger: messenger
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
}
