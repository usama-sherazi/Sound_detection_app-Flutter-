import Flutter
import UIKit

class FLEmbedView : UIView {
  
  override func layoutSubviews() {
    super.layoutSubviews()
      subviews.forEach({ view in
          view.frame = self.frame
      })
  }
}

class FLNativeViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private var isOut: Bool

    init(isOut: Bool, messenger: FlutterBinaryMessenger) {
        self.isOut = isOut
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return FLNativeView(
            isOut: isOut,
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
    }
}

class FLNativeView: NSObject, FlutterPlatformView {
    private var _view: FLEmbedView
    private var imageView: UIImageView
    private var isOut: Bool

    init(
        isOut: Bool,
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = FLEmbedView()
        self.isOut = isOut
        imageView = UIImageView()
        _view.addSubview(imageView)
        if (isOut) {
            SipWrapper.shared().setupOutView(imageView: imageView)
        } else {
            SipWrapper.shared().setupIncView(imageView: imageView)
        }
        super.init()
    }

    func view() -> UIView {
        return _view
    }

}
