package org.abtollc.voip.abto_voip_sdk;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

public class AbtoVoipSdkPlugin implements FlutterPlugin {

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
      flutterPluginBinding
              .getPlatformViewRegistry()
              .registerViewFactory("out_video", new VideoViewFactory(true));
      flutterPluginBinding
              .getPlatformViewRegistry()
              .registerViewFactory("inc_video", new VideoViewFactory(false));
      SipWrapper.getInstance().setup(flutterPluginBinding);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
      SipWrapper.getInstance().clear();
  }
}
