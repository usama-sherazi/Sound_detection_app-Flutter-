import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class IosVoipVideoWidget extends StatelessWidget {
  bool isOut;
  IosVoipVideoWidget(this.isOut, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    return UiKitView(
      viewType: isOut ? 'out_video' : 'inc_video',
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

class AndroidVoipVideoWidget extends StatelessWidget {
  bool isOut;
  AndroidVoipVideoWidget(this.isOut, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    return AndroidView(
      viewType: isOut ? 'out_video' : 'inc_video',
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

class VoipVideoWidget extends StatelessWidget {
  bool isOut;

  VoipVideoWidget(this.isOut, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidVoipVideoWidget(isOut);
      case TargetPlatform.iOS:
        return IosVoipVideoWidget(isOut);
      default:
        throw UnsupportedError('Unsupported platform view');
    }
  }
}