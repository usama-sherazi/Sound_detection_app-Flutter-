import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:flutter/services.dart';
import 'package:huawei_ml_language/huawei_ml_language.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import 'package:abto_voip_sdk/sip_wrapper.dart';

import 'Settings.dart';

class SoundDetection extends StatefulWidget {
  const SoundDetection({super.key});

  @override
  _SoundDetectionState createState() => _SoundDetectionState();
}

class _SoundDetectionState extends State<SoundDetection> {
  bool _cryingBaby = false;
  bool _shoutingPet = false;
  StreamSubscription<List<int>>? _micStreamSubscription;
  late MLSoundDetector _mlSoundDetector;


  bool _isCallActive = false;
  final String _callNumber = '901';

  @override
  void initState() {
    super.initState();
    _initializeSipWrapper();
    _loadPreferences();
    _initSoundDetector();
    _initMicStream();
  }

  void _initializeSipWrapper() {
    SipWrapper.wrapper.init();

    if (Platform.isAndroid) {
      SipWrapper.wrapper.setLicense(
          'Trial_dostmhd@gmail.com_Android-D23D-F747-ABDA4AB9-7081-D1D6-C378-2D5BC712901E',
          'vRjZgZsVIfkqIayDzfLAxeMB5vOFxFzUy8SFGS+9qGlL4BhnZ3UCX9pl8YWfAwHIrmPfOmaihiREcVnrr0suqg==');
    } else if (Platform.isIOS) {
      SipWrapper.wrapper.setLicense('iosLicenseUserId', 'iosLicenseKey');
    }

    SipWrapper.wrapper.register(
        '192.168.100.19', '', '905', '1234', '905', 'Sound detection', 3600);

    SipWrapper.wrapper.registerListener = RegisterListener(onRegistered: () {
      print('SIP Registered successfully');
    }, onRegistrationFailed: () {
      print('SIP Registration failed');
    }, onUnregistered: () {
      print('SIP Unregistered');
    });

    SipWrapper.wrapper.callListener = CallListener(callConnected: (number) {
      print('Call connected with number: $number');
      setState(() {
        _isCallActive = true;
      });
    }, callDisconnected: () {
      print('Call disconnected');
      setState(() {
        _isCallActive = false;
      });
    });
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cryingBaby = prefs.getBool('cryingBaby') ?? false;
      _shoutingPet = prefs.getBool('Shouting-pet') ?? false;
    });

    _manageMicStream();
  }

  void _initSoundDetector() {
    _mlSoundDetector = MLSoundDetector();
    _mlSoundDetector.setSoundDetectListener(onDetection);
  }

  void _initMicStream() async {
    try {
      var stream = await MicStream.microphone(
        sampleRate: 44100,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT,
      );
      _micStreamSubscription = stream.listen((data) {
        _processMicData(data);
      });
    } on PlatformException catch (e) {
      print("Error initializing microphone stream: $e");
    }
  }

  void _processMicData(List<int> data) {
    // Implement additional logic if needed
  }

  void _manageMicStream() {
    if (_cryingBaby || _shoutingPet) {
      _mlSoundDetector.start();
      _micStreamSubscription?.resume();
      if (!_isCallActive) {
        _startCall();
      }
    } else {
      _mlSoundDetector.stop();
      _micStreamSubscription?.pause();
      if (_isCallActive) {
        _endCall();
      }
    }
  }

  void _startCall() {
    SipWrapper.wrapper
        .startCall(_callNumber, false);
  }

  void _endCall() {
    SipWrapper.wrapper.endCall();
  }

  void _openSettingsOverlay(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => const Settings(),
      isScrollControlled: true,
    );

    _loadPreferences();
  }

  void onDetection({int? result, int? errCode}) {
    if (errCode != null) {
      print("Error detecting sound: $errCode");
      return;
    }

    if (result != null) {
      setState(() {
        _cryingBaby =
            result == MLSoundDetectConstants.SOUND_EVENT_TYPE_BABY_CRY;
        _shoutingPet = result == MLSoundDetectConstants.SOUND_EVENT_TYPE_BARK;

        if (_cryingBaby) {
          _showNotification('Sound Detected', 'Crying baby sound detected');
        }

        if (_shoutingPet) {
          _showNotification('Sound Detected', 'Shouting pet sound detected');
        }

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
            const SizedBox(height: 80.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 230.0,
                  width: 350,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 10.0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_cryingBaby)
                          SvgPicture.asset(
                            'assets/icons/cryingbaby.svg',
                            width: 30.0,
                            height: 60.0,
                          ),
                        const SizedBox(height: 40.0),
                        if (_shoutingPet)
                          const Icon(
                            Icons.pets,
                            size: 70.0,
                            color: Colors.green,
                          ),
                        if (!_cryingBaby && !_shoutingPet)
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 80.0,
                                color: Colors.red,
                              ),
                              SizedBox(height: 10.0),
                              Text(
                                'Detecting 0 sounds',
                                style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
