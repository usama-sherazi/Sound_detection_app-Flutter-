import Flutter
import UIKit

public class SwiftAbtoVoipSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
      registrar.register(
        FLNativeViewFactory(isOut: true, messenger: registrar.messenger()),
        withId: "out_video"
      )
      registrar.register(
        FLNativeViewFactory(isOut: false, messenger: registrar.messenger()),
        withId: "inc_video"
      )
      SipWrapper.shared().setup(binaryMessenger: registrar.messenger())
  }
}
