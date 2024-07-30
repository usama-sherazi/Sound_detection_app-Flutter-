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
  bool _laughing = false; // Added for laughing detection
  bool _isRegistering = true;
  bool _isRegistered = false;
  StreamSubscription<List<int>>? _micStreamSubscription;
  late MLSoundDetector _mlSoundDetector;

  bool _isCallActive = false;


  @override
  void initState() {
    super.initState();
    _initializeSipWrapper();
    _loadPreferences();
    _initSoundDetector();
    _initMicStream();
  }

  void _initializeSipWrapper() async {
    final prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username') ?? '';
    String password = prefs.getString('password') ?? '';
    String domain = prefs.getString('domain') ?? '';

    if (username.isEmpty || password.isEmpty || domain.isEmpty) {
      print('SIP registration details are missing');
      return;
    }

    SipWrapper.wrapper.init();

    if (Platform.isAndroid) {
      SipWrapper.wrapper.setLicense(
          '{Trial0e81_Android-D249-144A-ABEB5BD1-B97D-484B-BFEA-DA604244101E}',
          '{AufGKw0AgccH6hw/qP88p6K/O33xQGlwF3BCpGLzY6s9w2xzti0JHPOBe9saTPjoHPUnaRwHXO98OjA4bmx/Og==}'
      );
    } else if (Platform.isIOS) {
      SipWrapper.wrapper.setLicense(
          '{Trial0e81_iOS-D249-147A-BBEB5BD1-B97D-484B-BFEA-DA604244101E}',
          '{Ix6BNIR+1jeZRkZ17CQ6LsHEgu9l7+md9CjIM0N94cbErGCcDS01hcEvCdfw6W4p037IkZpEwoCBfzUaMfYmZg==}'
      );
    }

    SipWrapper.wrapper.register(
        domain, '', username, password, '', 'Flutter_APP', 3600
    );

    SipWrapper.wrapper.registerListener = RegisterListener(onRegistered: () {
      print('SIP Registered successfully');
      setState(() {
        _isRegistered = true;
        _isRegistering = false;
      });
    }, onRegistrationFailed: () {
      print('SIP Registration failed');
      setState(() {
        _isRegistering = false;
      });
    }, onUnregistered: () {
      print('SIP Unregistered');
      setState(() {
        _isRegistered = false;
        _isRegistering = false;
      });
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
      _laughing = prefs.getBool('laughing') ?? false; // Load laughing preference

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
    if (_cryingBaby || _shoutingPet || _laughing) {
      _mlSoundDetector.start();
      _micStreamSubscription?.resume();
    } else {
      _mlSoundDetector.stop();
      _micStreamSubscription?.pause();
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
      }
    }
  }

  void _endCall() {
    if (_isCallActive) {
      SipWrapper.wrapper.endCall();
    }
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
        _cryingBaby = result == MLSoundDetectConstants.SOUND_EVENT_TYPE_BABY_CRY;
        _shoutingPet = result == MLSoundDetectConstants.SOUND_EVENT_TYPE_BARK;
        _laughing = result == MLSoundDetectConstants.SOUND_EVENT_TYPE_LAUGHTER;

        if (_cryingBaby) {
          _showNotification('Sound Detected', 'Crying baby sound detected');
        }

        if (_shoutingPet) {
          _showNotification('Sound Detected', 'Shouting pet sound detected');
        }

        if (_laughing) {
          _showNotification('Sound Detected', 'Laughing sound detected');
        }

        if (_cryingBaby) {
          _startCall('cryingBaby');
        } else if (_shoutingPet) {
          _startCall('shoutingPet');
        } else if (_laughing) {
          _startCall('laughing');
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
                        if (!_cryingBaby && !_shoutingPet && !_laughing)
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
