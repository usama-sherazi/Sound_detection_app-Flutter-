import 'package:flutter/cupertino.dart';

class AbtoPhoneCfg {
  static const int SIGNALING_TRANSPORT_UDP = 1;
  static const int SIGNALING_TRANSPORT_TCP = 2;
  static const int SIGNALING_TRANSPORT_TLS = 2;

  bool isSTUNEnabled = false;
  String stunServer = "";
  int sipPort = 0;
  int signalingTransport = SIGNALING_TRANSPORT_UDP;
  bool isICEEnabled = false;
  int keepAliveInterval = 0;
  int inviteTimeout = 0;
  int hangupTimeout = 0;
  int registerTimeout = 0;
  bool isUseSRTP = false;
  bool isEnabledAutoSendRtpVideo = false;
  Map<AudioCodec, int> audioCodecs = <AudioCodec, int>{};
  Map<VideoCodec, int> videoCodecs = <VideoCodec, int>{};
}

enum AudioCodec { GSM, PCMA, PCMU, ILBC, SPEEDX, G729, G722, G722_1, AMR, G723, SILK, OPUS }
enum VideoCodec { H264, H263, VP8 }

extension AudioCodecExt on AudioCodec {
  String name() { return toString().split('.').last; }
}

extension VideoCodecExt on VideoCodec {
  String name() { return toString().split('.').last; }
}

extension AbtoPhoneCfgExt on AbtoPhoneCfg {

  String audioCodecsString() {
    var data = "";
    audioCodecs.forEach((codec, priority) {
      data += "${codec.name()}-$priority;";
    });
    return data;
  }

  String videoCodecsString() {
    var data = "";
    videoCodecs.forEach((codec, priority) {
      data += "${codec.name()}-$priority;";
    });
    return data;
  }
}

extension AbtoPhoneCfgParseExt on String {

  Map<AudioCodec, int> parseAudioCodecs() {
    Map<AudioCodec, int> map = <AudioCodec, int>{};
    split(";").forEach((element) {
      List<String> pair = element.split("-");
      if (pair.length == 2) {
        debugPrint("find: " + pair.first);
        AudioCodec codec = AudioCodec.values.firstWhere((codec) =>
        codec.name() == pair.first);
        map[codec] = int.parse(pair[1]);
      }
    });
    return map;
  }

  Map<VideoCodec, int> parseVideoCodecs() {
    Map<VideoCodec, int> map = <VideoCodec, int>{};
    split(";").forEach((element) {
      List<String> pair = element.split("-");
      if (pair.length == 2) {
        VideoCodec codec = VideoCodec.values.firstWhere((codec) =>
        codec.name() == pair.first);
        map[codec] = int.parse(pair[1]);
      }
    });
    return map;
  }

}