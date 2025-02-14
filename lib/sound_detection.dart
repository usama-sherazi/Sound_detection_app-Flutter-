import 'dart:async';
import 'dart:io';

import 'package:abto_voip_sdk/sip_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:huawei_ml_language/huawei_ml_language.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Settings.dart';

class SoundDetection extends StatefulWidget {
  const SoundDetection({super.key});

  @override
  _SoundDetectionState createState() => _SoundDetectionState();
}

class _SoundDetectionState extends State<SoundDetection> {
  bool _cryingBaby = false;
  bool _shoutingPet = false;
  bool _laughing = false;
  bool _isRegistering = true;
  bool _isRegistered = false;
  StreamSubscription<List<int>>? _micStreamSubscription;
  late MLSoundDetector _mlSoundDetector;

  bool _isCallActive = false;
  String _detectedSound = 'No sound';
  final ValueNotifier<String> _registerationStatus = ValueNotifier<String>("--");
  final ValueNotifier<String> _detectionStatus = ValueNotifier<String>("--");
  final ValueNotifier<String> _detectionSound = ValueNotifier<String>("No sound");
  final ValueNotifier<String> _callStatus = ValueNotifier<String>("");

  @override
  void initState() {
    super.initState();
    _initializeSipWrapper();
    _loadPreferences();
    _initSoundDetector();
    _initMicStream();
  }

  Future<void> _initializeSipWrapper() async {
    final prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username') ?? '';
    String password = prefs.getString('password') ?? '';
    String domain = prefs.getString('domain') ?? '';

    if (username.isEmpty || password.isEmpty || domain.isEmpty) {
      print('SIP registration details are missing');
      _registerationStatus.value = "SIP account not configured";
      return;
    }

    SipWrapper.wrapper.init();

    if (Platform.isAndroid) {
      SipWrapper.wrapper.setLicense(
        '{Trial0e81_Android-D249-144A-ABEB5BD1-B97D-484B-BFEA-DA604244101E}',
        '{AufGKw0AgccH6hw/qP88p6K/O33xQGlwF3BCpGLzY6s9w2xzti0JHPOBe9saTPjoHPUnaRwHXO98OjA4bmx/Og==}',
      );
    } else if (Platform.isIOS) {
      SipWrapper.wrapper.setLicense(
        '{Trial0e81_iOS-D249-147A-BBEB5BD1-B97D-484B-BFEA-DA604244101E}',
        '{Ix6BNIR+1jeZRkZ17CQ6LsHEgu9l7+md9CjIM0N94cbErGCcDS01hcEvCdfw6W4p037IkZpEwoCBfzUaMfYmZg==}',
      );
    }

    _registerSip(username, password, domain);
  }

  void _registerSip(String username, String password, String domain) {
    SipWrapper.wrapper.register(domain, '', username, password, '', 'Flutter_APP', 3600);
    _registerationStatus.value = "SIP registering";

    SipWrapper.wrapper.registerListener = RegisterListener(
      onRegistered: () {
        print('SIP Registered successfully');
        setState(() {
          _isRegistered = true;
          _isRegistering = false;
          _registerationStatus.value = "SIP Registered";
        });
      },
      onRegistrationFailed: () {
        print('SIP Registration failed');
        _registerationStatus.value = "SIP Registration failed";
        setState(() {
          _isRegistering = false;
        });
      },
      onUnregistered: () {
        print('SIP Unregistered');
        _registerationStatus.value = "SIP Unregistered";
        setState(() {
          _isRegistered = false;
          _isRegistering = false;
        });
      },
    );

    SipWrapper.wrapper.callListener = CallListener(
      callConnected: (number) {
        print('Call connected with number: $number');
        setState(() {
          _isCallActive = true;
          _registerationStatus.value = "SIP on Active Call";
          _callStatus.value = "connected $number";
        });
      },
      callDisconnected: () {
        print('Call disconnected');
        _callStatus.value = "";
        setState(() {
          _isCallActive = false;
        });
      },
    );
  }

  void _unregisterSipWrapper() {
    SipWrapper.wrapper.unregister();
    _registerationStatus.value = "SIP Unregistered";
    setState(() {
      _isRegistered = false;
      _isRegistering = false;
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cryingBaby = prefs.getBool('cryingBaby') ?? false;
      _shoutingPet = prefs.getBool('Shouting-pet') ?? false;
      _laughing = prefs.getBool('laughing') ?? false;
    });
    _manageMicStream();
  }

  void _initSoundDetector() {
    _mlSoundDetector = MLSoundDetector();
    _detectionStatus.value = "detection started";
    _mlSoundDetector.setSoundDetectListener(onDetection);
  }

  Future<void> _initMicStream() async {
    try {
      var stream = await MicStream.microphone(
        sampleRate: 44100,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT,
      );
      _micStreamSubscription = stream.listen(_processMicData);
    } on PlatformException catch (e) {
      print("Error initializing microphone stream: $e");
    }
  }

  void _processMicData(List<int> data) {
    // Implement additional logic if needed
  }

  void _manageMicStream() {
    if (_cryingBaby || _shoutingPet || _laughing) {
      _mlSoundDetector.start();
      _micStreamSubscription?.resume();
      _detectionStatus.value = "detection started";
    } else {
      _mlSoundDetector.stop();
      _micStreamSubscription?.pause();
      _detectionStatus.value = "detection stopped";
    }
  }

  Future<void> _startCall(String soundType) async {
    if (_isRegistered && !_isCallActive) {
      final prefs = await SharedPreferences.getInstance();
      String? callNumber;
      if (soundType == 'cryingBaby') {
        callNumber = prefs.getString('phoneCryingBaby');
      } else if (soundType == 'shoutingPet') {
        callNumber = prefs.getString('phoneShoutingPet');
      } else if (soundType == 'laughing') {
        callNumber = prefs.getString('phoneLaughing');
      }

      if (callNumber != null && callNumber.isNotEmpty) {
        SipWrapper.wrapper.startCall(callNumber, false);
        _callStatus.value = "calling $callNumber";
      }
    }
  }

  void _endCall() {
    if (_isCallActive) {
      SipWrapper.wrapper.endCall();
      _callStatus.value = "";
    }
  }

  Future<void> _openSettingsOverlay(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => const Settings(),
      isScrollControlled: true,
    );

    _unregisterSipWrapper();
    _initializeSipWrapper();
    _loadPreferences();
  }

  void onDetection({int? result, int? errCode}) {
    if (errCode != null) {
      print("Error detecting sound: $errCode");
      return;
    }

    if (result != null) {
      setState(() {
        _cryingBaby = result == MLSoundDetectConstants.SOUND_EVENT_TYPE_BABY_CRY;
        _shoutingPet = result == MLSoundDetectConstants.SOUND_EVENT_TYPE_BARK;
        _laughing = result == MLSoundDetectConstants.SOUND_EVENT_TYPE_LAUGHTER;

        if (_cryingBaby) {
          _detectedSound = 'Crying Baby';
          _showNotification('Sound Detected', 'Crying baby sound detected');
          _startCall('cryingBaby');
        } else if (_shoutingPet) {
          _detectedSound = 'Shouting Pet';
          _showNotification('Sound Detected', 'Shouting pet sound detected');
          _startCall('shoutingPet');
        } else if (_laughing) {
          _detectedSound = 'Laughing';
          _showNotification('Sound Detected', 'Laughing sound detected');
          _startCall('laughing');
        } else {
          _detectedSound = 'No sound';
        }
        _detectionSound.value = _detectedSound;
        _manageMicStream();
      });
    }
  }

  void _showNotification(String title, String body) {
    Fluttertoast.showToast(
      msg: "$title: $body",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  void dispose() {
    _micStreamSubscription?.cancel();
    _mlSoundDetector.destroy();
    _detectionStatus.value = "detection stopped";
    SipWrapper.wrapper.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Detector App'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _openSettingsOverlay(context),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.earbuds_sharp, size: 40),
              SizedBox(width: 10.0),
              Text(
                'Listening for sounds...',
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_cryingBaby)
                SvgPicture.asset(
                  'assets/icons/cryingbaby.svg',
                  width: 50.0,
                  height: 50.0,
                ),
              if (_shoutingPet)
                const Icon(
                  Icons.pets,
                  size: 50.0,
                  color: Colors.green,
                ),
              if (_laughing)
                const Icon(
                  Icons.sentiment_satisfied,
                  size: 50.0,
                  color: Colors.yellow,
                ),
            ],
          ),
          const SizedBox(height: 20.0),
          Container(
            height: 230.0,
            width: 350,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 10.0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: _detectedSound.isNotEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_detectedSound == 'Crying Baby')
                          SvgPicture.asset(
                            'assets/icons/cryingbaby.svg',
                            width: 50.0,
                            height: 50.0,
                          ),
                        if (_detectedSound == 'Shouting Pet')
                          const Icon(
                            Icons.pets,
                            size: 50.0,
                            color: Colors.green,
                          ),
                        if (_detectedSound == 'Laughing')
                          const Icon(
                            Icons.sentiment_satisfied,
                            size: 50.0,
                            color: Colors.yellow,
                          ),
                        const SizedBox(height: 10.0),
                        Text(
                          '$_detectedSound detected',
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80.0,
                          color: Colors.red,
                        ),
                        SizedBox(height: 10.0),
                        Text(
                          'No sound detected',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 80.0),
          ValueListenableBuilder<String>(
            valueListenable: _registerationStatus,
            builder: (BuildContext context, String value, child) {
              return Text(
                "SIP: $value",
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 10.0),
          ValueListenableBuilder<String>(
            valueListenable: _detectionStatus,
            builder: (BuildContext context, String value, child) {
              return Text(
                "SD: $value",
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          ValueListenableBuilder<String>(
            valueListenable: _callStatus,
            builder: (BuildContext context, String value, child) {
              return Text(
                "$value",
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ]),
      ),
    );
  }
}
