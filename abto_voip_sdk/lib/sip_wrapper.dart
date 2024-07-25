import 'package:abto_voip_sdk/abto_phone_cfg.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SipWrapper {
  // Android SDK: 20210219
  // IOS SDK: 20210219

  static final SipWrapper wrapper = SipWrapper.internal(); // singleton

  SipWrapper.internal();

  // Events
  static const String _EVENT_LIB_VERSION = "libVersion";

  static const String _EVENT_INIT_LICENSE = "initLicense";
  static const String _EVENT_REGISTER = "register";
  static const String _EVENT_UNREGISTER = "unregister";

  static const String _EVENT_START_AUDIO_CALL = "startAudioCall";
  static const String _EVENT_START_VIDEO_CALL = "startVideoCall";
  static const String _EVENT_PICK_UP_CALL = "pickUpCall";
  static const String _EVENT_END_CALL = "endCall";
  static const String _EVENT_HANG_UP_CALL = "hangUpCall";
  static const String _EVENT_REJECT_CALL = "rejectCall";

  static const String _EVENT_ENABLE_SPEAKER = "enableSpeaker";
  static const String _EVENT_HOLD = "hold";
  static const String _EVENT_MUTE = "mute";
  static const String _EVENT_START_RECORD = "startRecord";
  static const String _EVENT_STOP_RECORD = "stopRecord";
  static const String _EVENT_TRANSFER = "transfer";

  static const String _EVENT_SEND_TEXT = "sendText";
  static const String _EVENT_GET_CONFIGS = "getConfigs";
  static const String _EVENT_SET_CONFIGS = "setConfigs";

  static const String _EVENT_SET_LOG_LEVEL = "setLogLevel";
  static const String _EVENT_SET_SENDING_RTP_VIDEO = "setSendingRtpVideo";

  static const String _EVENT_SEND_DTMF = "sendDtmf";
  static const String _EVENT_MUTE_LOCAL_VIDEO = "muteLocalVideo";

  // Results
  static const String _RESULT_REGISTERED = "registered";
  static const String _RESULT_UNREGISTERED = "unregistered";
  static const String _RESULT_REG_FAILED = "registration_failed";

  static const String _RESULT_CALL_CONNECTED = "call_connected";
  static const String _RESULT_CALL_DISCONNECTED = "call_disconnected";

  static const String _RESULT_ON_HOLD_STATE = "on_hold_state";
  static const String _RESULT_ACTIVE = "active";
  static const String _RESULT_LOCAL_HOLD = "local_hold";
  static const String _RESULT_REMOTE_HOLD = "remote_hold";

  static const String _RESULT_INCOMING_CALL = "incoming_call";

  static const String _RESULT_MSG_RECEIVED = "message_received";
  static const String _RESULT_MSG_STATUS = "message_status";

  static const String _RESULT_DTMF_RECEIVED = "dtmf_received";

  SipChannel? _channel;
  bool _isRegistered = false;

  RegisterListener? registerListener;
  CallListener? callListener;
  HoldStateListener? holdStateListener;
  IncomingCallListener? incomingCallListener;
  TextMessageListener? textMessageListener;
  DtmfStateListener? dtmfListener;

  void init() {
    debugPrint("SipWrapper init");
    if (_channel != null) return;
    _channel = SipChannel();
    _channel?.addListener(_stateChanged);
  }

  void setLicense(String userId, String key) {
    debugPrint("SipWrapper setLicense\n" + userId + "\n" + key);
    _channel?.platform?.invokeMethod(_EVENT_INIT_LICENSE, [userId, key]);
  }

  Future<String> getVersion() {
    if (_channel == null) return Future.value("error no channel");
    debugPrint("SipWrapper getVersion");
    return _channel?.platform?.invokeMethod<String>(_EVENT_LIB_VERSION).then<String>((String? value) => value ?? "error null") ?? Future.value("error empty");
  }

  Future<AbtoPhoneCfg> getConfigs() {
    debugPrint("SipWrapper getConfigs");
    Future<AbtoPhoneCfg>? result = _channel?.platform
        ?.invokeMethod<Map<Object?, Object?>>(_EVENT_GET_CONFIGS).then(
            (value) {
          AbtoPhoneCfg configs = AbtoPhoneCfg();
          configs.isSTUNEnabled = value?["isSTUNEnabled"] as bool;
          configs.stunServer = value?["STUNServer"] as String;
          configs.sipPort = value?["SipPort"] as int;
          configs.signalingTransport = value?["SignalingTransport"] as int;
          configs.isICEEnabled = value?["ICEEnabled"] as bool;
          configs.keepAliveInterval = value?["KeepAliveInterval"] as int;
          configs.inviteTimeout = value?["InviteTimeout"] as int;
          configs.hangupTimeout = value?["HangupTimeout"] as int;
          configs.registerTimeout = value?["RegisterTimeout"] as int;
          configs.isUseSRTP = value?["isUseSRTP"] as bool;
          configs.audioCodecs = (value?["audioCodecs"] as String).parseAudioCodecs();
          configs.videoCodecs = (value?["videoCodecs"] as String).parseVideoCodecs();
          configs.isEnabledAutoSendRtpVideo = value?["isEnabledAutoSendRtpVideo"] as bool;
          return configs;
        }
    );

    return result ?? Future.value(AbtoPhoneCfg());
  }

  void setConfigs(AbtoPhoneCfg cfg) {
    debugPrint("SipWrapper setConfigs");
    Map<Object?, Object?> map = {
      "isSTUNEnabled": cfg.isSTUNEnabled,
      "STUNServer": cfg.stunServer,
      "SipPort": cfg.sipPort,
      "SignalingTransport": cfg.signalingTransport,
      "ICEEnabled": cfg.isICEEnabled,
      "KeepAliveInterval": cfg.keepAliveInterval,
      "InviteTimeout": cfg.inviteTimeout,
      "HangupTimeout": cfg.hangupTimeout,
      "RegisterTimeout": cfg.registerTimeout,
      "isUseSRTP": cfg.isUseSRTP,
      "audioCodecs": cfg.audioCodecsString(),
      "videoCodecs": cfg.videoCodecsString(),
      "isEnabledAutoSendRtpVideo": cfg.isEnabledAutoSendRtpVideo,
    };
    _channel?.platform?.invokeMethod(_EVENT_SET_CONFIGS, map);
  }

  void register(String domain, String proxy, String user, String pass, String authId, String displName, int expire) {
    debugPrint("SipWrapper register " + user);
    _channel?.platform?.invokeMethod(_EVENT_REGISTER,
        [domain, proxy, user, pass, authId, displName, expire.toString()]);
  }

  void destroy() {
    if (_channel == null) return;
    _channel?.removeListener(_stateChanged);
  }

  void unregister() {
    _channel?.platform?.invokeMethod(_EVENT_UNREGISTER);
  }

  void startCall(String number, bool isVideo) {
    debugPrint("SipWrapper startCall to [" + number + "] video " + isVideo.toString());
    _channel?.platform?.invokeMethod(
        isVideo ? _EVENT_START_VIDEO_CALL : _EVENT_START_AUDIO_CALL, number);
  }

  void endCall() {
    debugPrint("SipWrapper endCall");
    _channel?.platform?.invokeMethod(_EVENT_END_CALL);
    _finishCall();
  }

  void pickUpCall(bool isVideo) {
    debugPrint("SipWrapper pickUpCall");
    _channel?.platform?.invokeMethod(_EVENT_PICK_UP_CALL, isVideo);
  }

  void hangUpCall(int status) {
    debugPrint("SipWrapper hangUpCall");
    _channel?.platform?.invokeMethod(_EVENT_HANG_UP_CALL, status);
  }

  void rejectCall() {
    debugPrint("SipWrapper rejectCall");
    _channel?.platform?.invokeMethod(_EVENT_REJECT_CALL);
  }

  void muteLocalVideo(bool mute) {
    debugPrint("SipWrapper muteLocalVideo: " + mute.toString());
    _channel?.platform?.invokeMethod(_EVENT_MUTE_LOCAL_VIDEO, mute);
  }

  void sendDtmf(String tone) {
    debugPrint("SipWrapper muteLocalVideo: " + tone);
    _channel?.platform?.invokeMethod(_EVENT_SEND_DTMF, tone);
  }

  void enableSpeaker(bool enable) {
    debugPrint("SipWrapper enableSpeaker: " + enable.toString());
    _channel?.platform?.invokeMethod(_EVENT_ENABLE_SPEAKER, enable);
  }

  void hold() {
    debugPrint("SipWrapper hold");
    _channel?.platform?.invokeMethod(_EVENT_HOLD);
  }

  void mute(bool enable) {
    debugPrint("SipWrapper mute: " + enable.toString());
    _channel?.platform?.invokeMethod(_EVENT_MUTE, enable);
  }

  void startRecord() {
    debugPrint("SipWrapper startRecord");
    _channel?.platform?.invokeMethod(_EVENT_START_RECORD);
  }

  void stopRecord() {
    debugPrint("SipWrapper stopRecord");
    _channel?.platform?.invokeMethod(_EVENT_STOP_RECORD);
  }

  void transferCall(String number) {
    debugPrint("SipWrapper transferCall: " + number);
    _channel?.platform?.invokeMethod(_EVENT_TRANSFER, number);
  }

  void sendTextMessage(String number, String message) {
    debugPrint("SipWrapper sendTextMessage: " + number + " msg: " + message);
    _channel?.platform?.invokeMethod(_EVENT_SEND_TEXT, [number, message]);
  }

  void setLogLevel(int logLevel, bool toFile) {
    debugPrint("SipWrapper setLogLevel: $logLevel, $toFile");
    _channel?.platform?.invokeMethod(_EVENT_SET_LOG_LEVEL, [logLevel, toFile ? 1 : 0]);
  }

  void setSendingRtpVideo(bool enable) {
    debugPrint("SipWrapper setSendingRtpVideo: $enable");
    _channel?.platform?.invokeMethod(_EVENT_SET_SENDING_RTP_VIDEO, enable);
  }

  void _stateChanged() {
    debugPrint("SipWrapper stateChanged " + (_channel?.methodName ?? ""));
    switch (_channel?.methodName) {
      case _RESULT_REGISTERED:
        debugPrint("SipWrapper stateChanged: _isRegistered: " +
            _isRegistered.toString());
        if (_isRegistered) return;
        _isRegistered = true;
        debugPrint("SipWrapper stateChanged: registerListener != null: " +
            (registerListener != null).toString());
        registerListener?.onRegistered?.call();
        break;
      case _RESULT_REG_FAILED:
        if (_isRegistered) return;
        registerListener?.onRegistrationFailed?.call();
        break;
      case _RESULT_UNREGISTERED:
        if (!_isRegistered) return;
        _isRegistered = false;
        registerListener?.onUnregistered?.call();
        break;

      case _RESULT_CALL_CONNECTED:
        debugPrint("SipWrapper callConnected");
        String number =
            StringUtil.minifySipContact(_channel?.arguments as String);
        callListener?.callConnected?.call(number);
        break;
      case _RESULT_CALL_DISCONNECTED:
        debugPrint("SipWrapper callDisconnected");
        _finishCall();
        break;

      case _RESULT_INCOMING_CALL:
        if (_channel?.arguments == null) return;

        List<dynamic> list = _channel?.arguments as List<dynamic>;
        String number = StringUtil.minifySipContact(list[0].toString());
        bool isVideo = list[1] == 'true';

        incomingCallListener?.onIncomingCall?.call(number, isVideo);
        break;

      case _RESULT_ON_HOLD_STATE:
        if (_channel?.arguments == null) return;

        debugPrint(
            "_RESULT_ON_HOLD_STATE: " + (_channel?.arguments.toString() ?? ""));
        // List<dynamic> list = _channel?.arguments as List<dynamic>;
        String? state = _channel?.arguments.toString();

        if (holdStateListener != null) {
          switch (state) {
            case _RESULT_ACTIVE:
              holdStateListener?.onHoldState?.call(HoldState.ACTIVE);
              break;
            case _RESULT_LOCAL_HOLD:
              holdStateListener?.onHoldState?.call(HoldState.LOCAL_HOLD);
              break;
            case _RESULT_REMOTE_HOLD:
              holdStateListener?.onHoldState?.call(HoldState.REMOTE_HOLD);
              break;
          }
        }
        break;

      case _RESULT_MSG_RECEIVED:
        if (_channel?.arguments == null) return;

        List<dynamic> list = _channel?.arguments as List<dynamic>;
        String fromNumber = StringUtil.minifySipContact(list[0].toString());
        String toNumber = StringUtil.minifySipContact(list[1].toString());
        String message = list[2].toString();

        textMessageListener?.onTextMessageReceived?.call(fromNumber, toNumber, message);
        break;

      case _RESULT_MSG_STATUS:
        if (_channel?.arguments == null) return;

        List<dynamic> list = _channel?.arguments as List<dynamic>;
        String address = StringUtil.minifySipContact(list[0].toString());
        String reason = list[1].toString();
        bool success = list[2] == 'true';

        textMessageListener?.onTextMessageStatus?.call(address, reason, success);
        break;

      case _RESULT_DTMF_RECEIVED:
        if (_channel?.arguments == null) return;

        String tone = _channel?.arguments as String;

        dtmfListener?.onDtmfReceived?.call(tone);
        break;
    }
  }

  void _finishCall() {
    callListener?.callDisconnected?.call();
  }
}

// Channel
class SipChannel extends ValueNotifier<void> {
  static const CHANNEL_NAME = "com.voip.sdk.channel";

  MethodChannel? platform;
  Object? arguments;
  String methodName = "";

  SipChannel() : super('') {
    platform = const MethodChannel(CHANNEL_NAME);
    platform?.setMethodCallHandler(handleMethod);
  }

  Future<dynamic> handleMethod(MethodCall call) async {
    debugPrint("SipChannel handleMethod " + call.arguments.toString());
    methodName = call.method;
    arguments = call.arguments;
    notifyListeners();
  }
}

class RegisterListener {
  RegisterListener(
      {this.onRegistered, this.onRegistrationFailed, this.onUnregistered});

  void Function()? onRegistered;
  void Function()? onRegistrationFailed;
  void Function()? onUnregistered;
}

class CallListener {
  CallListener({this.callConnected, this.callDisconnected});

  void Function(String)? callConnected;
  void Function()? callDisconnected;
}

class HoldStateListener {
  HoldStateListener({this.onHoldState});

  void Function(HoldState)? onHoldState;
}

class IncomingCallListener {
  IncomingCallListener({this.onIncomingCall});

  void Function(String number, bool isVideoCall)? onIncomingCall;
}

class TextMessageListener {
  TextMessageListener({this.onTextMessageReceived, this.onTextMessageStatus});

  void Function(String from, String to, String message)? onTextMessageReceived;
  void Function(String address, String reason, bool success)? onTextMessageStatus;
}

class DtmfStateListener {
  DtmfStateListener({this.onDtmfReceived});

  void Function(String)? onDtmfReceived;
}

enum HoldState { ACTIVE, LOCAL_HOLD, REMOTE_HOLD }

class StringUtil {
  static String minifySipContact(String contact) {
    String result = contact.trim();
    int start = result.indexOf(":");
    int end = result.indexOf("@");
    if (start >= 0 && end > start) {
      result = result.substring(start + 1, end);
    }

    result = result
        .replaceAll("(", "")
        .replaceAll(")", "")
        .replaceAll(" ", "")
        .replaceAll("-", "")
        .replaceAll("+", "")
        .replaceAll(",", "");

    return result;
  }

  static bool isLetter(String char) {
    int symbol = char.codeUnitAt(0);

    if (symbol >= 'a'.codeUnitAt(0) && symbol <= 'z'.codeUnitAt(0)) return true;
    if (symbol >= 'A'.codeUnitAt(0) && symbol <= 'Z'.codeUnitAt(0)) return true;
    if (symbol >= 'а'.codeUnitAt(0) && symbol <= 'я'.codeUnitAt(0)) return true;
    if (symbol >= 'А'.codeUnitAt(0) && symbol <= 'Я'.codeUnitAt(0)) return true;

    return false;
  }
}
