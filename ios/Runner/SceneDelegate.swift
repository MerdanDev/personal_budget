import Flutter
import UIKit

/// Captures home-screen widget deep links (`wallet://add?type=…`) and forwards
/// them to Flutter.
///
/// The app runs under the scene-based lifecycle, so URL opens arrive on the
/// `UISceneDelegate` (`scene:openURLContexts:` while running, the connection
/// options on cold launch) rather than the app delegate. `home_widget` only
/// hooks the old `application:openURL:`, which UIKit no longer calls here — so
/// we handle the URL ourselves and hand it to `WidgetService` over a channel.
///
/// Subclasses `FlutterSceneDelegate` and calls `super` for every overridden
/// method so the standard Flutter window/engine setup is preserved.
class SceneDelegate: FlutterSceneDelegate {
  private static let channelName = "dev.merdan.wallet/widget"

  private var channel: FlutterMethodChannel?
  /// URL that cold-launched the app, held until Flutter pulls it via
  /// `getInitial` (Flutter may not have registered its handler yet at launch).
  private var initialURLString: String?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    setupChannel()
    if let url = connectionOptions.urlContexts.first?.url, isWidgetURL(url) {
      initialURLString = url.absoluteString
    }
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    if let url = URLContexts.first?.url, isWidgetURL(url) {
      setupChannel()
      channel?.invokeMethod("onUri", arguments: url.absoluteString)
    }
  }

  /// Creates the method channel against the scene's FlutterViewController once
  /// it exists. Idempotent.
  private func setupChannel() {
    guard channel == nil,
      let controller = window?.rootViewController as? FlutterViewController
    else { return }

    let ch = FlutterMethodChannel(
      name: SceneDelegate.channelName,
      binaryMessenger: controller.binaryMessenger
    )
    ch.setMethodCallHandler { [weak self] call, result in
      if call.method == "getInitial" {
        result(self?.initialURLString)
        self?.initialURLString = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    channel = ch
  }

  private func isWidgetURL(_ url: URL) -> Bool {
    return url.scheme == "wallet"
  }
}
