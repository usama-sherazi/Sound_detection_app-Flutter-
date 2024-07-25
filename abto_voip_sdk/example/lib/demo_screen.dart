import 'package:flutter/material.dart';

import 'package:abto_voip_sdk/sip_wrapper.dart';
import 'package:abto_voip_sdk/abto_video_widget.dart';
import 'package:abto_voip_sdk/abto_phone_cfg.dart';
import 'main.dart';
import 'dart:io' show Platform;

enum ScreenState {
  register,
  main,
  call,
}

enum CallState {
  incoming,
  outcoming,
  in_progress,
}

class DemoScreenState extends State<MyHomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  ScreenState? screenState;
  LoadingDialog loadingDialog = new LoadingDialog();

  // Register screen variables
  String _libVersion = "SDK version: ...";
  AbtoPhoneCfg _configs = AbtoPhoneCfg();
  TextEditingController? teLogin;
  TextEditingController? tePass;
  TextEditingController? teDomain;

  // Main screen variables
  TextEditingController? teNumber;

  // Call screen variables
  CallState? callState;
  String number = "";
  bool isVideoCall = false;

  // Constructor
  DemoScreenState() {
    SipWrapper.wrapper.init();

    if (Platform.isAndroid) {
      SipWrapper.wrapper.setLicense(
          "{YOUR_ANDROID_USER_ID}",
          "{YOUR_ANDROID_LICENSE_KEY}"
      );
    } else if (Platform.isIOS) {
      SipWrapper.wrapper.setLicense(
          "{YOUR_IOS_USER_ID}",
          "{YOUR_IOS_LICENSE_KEY}"
      );
    }

    getLibVersion();
    getConfigs();

    screenState = ScreenState.register;

    ////////////////////////////////////////////////////
    // Register listener
    ////////////////////////////////////////////////////
    SipWrapper.wrapper.registerListener = RegisterListener(onRegistered: () {
      setState(() {
        loadingDialog.hide(context);
        screenState = ScreenState.main;
      });
    }, onRegistrationFailed: () {
      loadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration failed")));
    }, onUnregistered: () {
      loadingDialog.hide(context);
      setState(() {
        screenState = ScreenState.register;
      });
    });

    ////////////////////////////////////////////////////
    // Call listener
    ////////////////////////////////////////////////////
    SipWrapper.wrapper.callListener = CallListener(callConnected: (String number) {
      setState(() {
        callState = CallState.in_progress;
        this.number = number;
      });
    }, callDisconnected: () {
      setState(() {
        screenState = ScreenState.main;
      });
    });

    ////////////////////////////////////////////////////
    // Incoming call listener
    ////////////////////////////////////////////////////
    SipWrapper.wrapper.incomingCallListener =
        IncomingCallListener(onIncomingCall: (number, isVideoCall) {
      setState(() {
        this.isVideoCall = isVideoCall;
        this.number = number;
        callState = CallState.incoming;
        screenState = ScreenState.call;
      });
    });

    ////////////////////////////////////////////////////
    // Text Message listener
    ////////////////////////////////////////////////////
    SipWrapper.wrapper.textMessageListener = TextMessageListener(onTextMessageReceived: ( from, to, message) {
        debugPrint("new message: " + message);
    }, onTextMessageStatus: (address, reason, success) {
        debugPrint("sent to : " + address + " reason: " + reason);
    });


    ////////////////////////////////////////////////////
    // Text Message listener
    ////////////////////////////////////////////////////
    SipWrapper.wrapper.dtmfListener = DtmfStateListener(onDtmfReceived: (tone) {
      debugPrint("new tone: " + tone);
    });

  }

  // Build view
  @override
  Widget build(BuildContext context) {
    loadingDialog.hide(context);
    debugPrint("screenState " + screenState.toString());
    Widget? body;
    switch (screenState) {
      case ScreenState.register:
        // Build register screen view
        body = Center(
            child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('Login:'),
                    TextFormField(
                      controller: teLogin = TextEditingController(
                        text: "" // You can put here your test credentials
                      ),
                    ),
                    SizedBox(height: 15),
                    Text('Password:'),
                    TextFormField(
                      controller: tePass = TextEditingController(
                          text: "" // You can put here your test credentials
                      ),
                    ),
                    SizedBox(height: 15),
                    Text('Domain:'),
                    TextFormField(
                      controller: teDomain = TextEditingController(
                          text: "" // You can put here your test credentials
                      ),
                    ),
                    SizedBox(height: 15),
                    Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      Checkbox(
                        value: _configs.isSTUNEnabled,
                        onChanged: (bool? value) {
                          setState(() {
                            _configs.isSTUNEnabled = !_configs.isSTUNEnabled;
                            updateConfigs();
                          });
                        },
                      ),
                      Text("STUN enabled")
                    ]),
                    SizedBox(height: 15),
                    MaterialButton(
                      minWidth: double.infinity,
                      height: 42.0,
                      color: Colors.lightGreen,
                      child: const Text("Register",
                          style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        ////////////////////////////////////////////////////
                        // Register
                        ////////////////////////////////////////////////////

                        String login = teLogin!.text;
                        String pass = tePass!.text;
                        String domain = teDomain!.text;

                        if (login.isEmpty || pass.isEmpty || domain.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Input all fields")));
                          return;
                        }

                        loadingDialog.show(context);
                        SipWrapper.wrapper.register(domain, "", login, pass, "", "", 300);
                      },
                    ),
                    SizedBox(height: 15),
                    Text("$_libVersion"),
                  ],
                ),
                padding: EdgeInsets.only(left: 60, right: 60)));
        break;
      // Build main screen view
      case ScreenState.main:
        body = Center(
            child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('Number:'),
                    TextFormField(
                      controller: teNumber = TextEditingController(),
                    ),
                    SizedBox(height: 15),
                    MaterialButton(
                      minWidth: double.infinity,
                      height: 42.0,
                      color: Colors.lightGreen,
                      child: Text("Audio call",
                          style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        setState(() {
                          ////////////////////////////////////////////////////
                          // Start audio call
                          ////////////////////////////////////////////////////
                          number = teNumber!.text;
                          isVideoCall = false;
                          callState = CallState.outcoming;
                          screenState = ScreenState.call;

                          SipWrapper.wrapper.startCall(number, isVideoCall);
                        });
                      },
                    ),
                    MaterialButton(
                      minWidth: double.infinity,
                      height: 42.0,
                      child: Text("Video call",
                          style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        setState(() {
                          ////////////////////////////////////////////////////
                          // Start video call
                          ////////////////////////////////////////////////////
                          number = teNumber!.text;
                          isVideoCall = true;
                          callState = CallState.outcoming;
                          screenState = ScreenState.call;

                          SipWrapper.wrapper.startCall(number, isVideoCall);
                        });
                      },
                      color: Colors.lightGreen,
                    ),
                    MaterialButton(
                      minWidth: double.infinity,
                      height: 42.0,
                      color: Colors.lightGreen,
                      child: Text("Sent Text Message 'Hello'",
                          style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        ////////////////////////////////////////////////////
                        // Send text message 'Hello'
                        ////////////////////////////////////////////////////
                        number = teNumber!.text;

                        SipWrapper.wrapper.sendTextMessage(number, "Hello");
                      },
                    ),
                    MaterialButton(
                      minWidth: double.infinity,
                      height: 42.0,
                      color: Colors.lightGreen,
                      child: Text("Unregister",
                          style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        ////////////////////////////////////////////////////
                        // Unregister
                        ////////////////////////////////////////////////////
                        loadingDialog.show(context);
                        SipWrapper.wrapper.unregister();
                      },
                    ),
                  ],
                ),
                padding: EdgeInsets.only(left: 60, right: 60)));
        break;
      // Build call screen view
      case ScreenState.call:
        switch (callState) {
          case CallState.incoming:
            body = Center(
                child: Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('Incoming call'),
                        Text(number),
                        SizedBox(height: 15),
                        MaterialButton(
                          minWidth: double.infinity,
                          height: 42.0,
                          color: Colors.lightGreen,
                          child: Text("End call",
                              style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            setState(() {
                              ////////////////////////////////////////////////////
                              // End call
                              ////////////////////////////////////////////////////
                              SipWrapper.wrapper.endCall();
                            });
                          },
                        ),
                        MaterialButton(
                          minWidth: double.infinity,
                          height: 42.0,
                          color: Colors.lightGreen,
                          child: Text("Answer Audio",
                              style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            setState(() {
                              ////////////////////////////////////////////////////
                              // Answer audio
                              ////////////////////////////////////////////////////
                              SipWrapper.wrapper.pickUpCall(false);
                            });
                          },
                        ),
                        if (isVideoCall)
                          MaterialButton(
                            minWidth: double.infinity,
                            height: 42.0,
                            color: Colors.lightGreen,
                            child: Text("Answer Video",
                                style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              setState(() {
                                ////////////////////////////////////////////////////
                                // Answer video
                                ////////////////////////////////////////////////////
                                SipWrapper.wrapper.pickUpCall(true);
                              });
                            },
                          ),
                      ],
                    ),
                    padding: EdgeInsets.only(left: 60, right: 60)));
            break;
          case CallState.outcoming:
            body = Center(
                child: Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('Outcoming call'),
                        Text(number),
                        SizedBox(height: 15),
                        MaterialButton(
                          minWidth: double.infinity,
                          height: 42.0,
                          color: Colors.lightGreen,
                          child: Text("End call",
                              style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            setState(() {
                              ////////////////////////////////////////////////////
                              // End call
                              ////////////////////////////////////////////////////
                              SipWrapper.wrapper.endCall();
                            });
                          },
                        ),
                      ],
                    ),
                    padding: EdgeInsets.only(left: 60, right: 60)));
            break;
          case CallState.in_progress:
            body = Center(
                child: Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('Call in progress...'),
                        Text(number),
                        SizedBox(height: 15),
                        MaterialButton(
                          minWidth: double.infinity,
                          height: 42.0,
                          color: Colors.lightGreen,
                          child: Text("End call",
                              style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            setState(() {
                              ////////////////////////////////////////////////////
                              // End call
                              ////////////////////////////////////////////////////
                              SipWrapper.wrapper.endCall();
                            });
                          },
                        ),
                        Row(
                          children: [
                            SizedBox(
                                width: 100,
                                height: 120,
                                child: VoipVideoWidget(true)
                            ),
                            SizedBox(
                                width: 100,
                                height: 120,
                                child: VoipVideoWidget(false)
                            )
                          ],
                        ),
                      ],
                    ),
                    padding: EdgeInsets.only(left: 60, right: 60)));
            break;
        }
        break;
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? "")),
      ////////////////////////////////////////////////////
      // Transparent background for video calls
      ////////////////////////////////////////////////////
      backgroundColor: screenState == ScreenState.call &&
          callState == CallState.in_progress &&
          isVideoCall
          ? Colors.transparent
          : Colors.white,
      body: body,
      key: _scaffoldKey,
    );
  }
  
  void getLibVersion() async {
    String libVersion;
    try {
      final String result = await SipWrapper.wrapper.getVersion();
      libVersion = 'SDK version: $result';
    } on Exception catch (e) {
      libVersion = "SDK version: error '${e}'";
    }

    setState(() {
      _libVersion = libVersion;
    });
  }

  void getConfigs() async {
    final AbtoPhoneCfg configs = await SipWrapper.wrapper.getConfigs();

    debugPrint('isSTUNEnabled: ${configs.isSTUNEnabled}');
    debugPrint('stunServer: ${configs.stunServer}');
    debugPrint('sipPort: ${configs.sipPort}');
    debugPrint('signalingTransport: ${configs.signalingTransport}');
    debugPrint('isICEEnabled: ${configs.isICEEnabled}');
    debugPrint('keepAliveInterval: ${configs.keepAliveInterval}');
    debugPrint('inviteTimeout: ${configs.inviteTimeout}');
    debugPrint('hangupTimeout: ${configs.hangupTimeout}');
    debugPrint('registerTimeout: ${configs.registerTimeout}');
    debugPrint('isUseSRTP: ${configs.isUseSRTP}');
    debugPrint('isEnabledAutoSendRtpVideo: ${configs.isEnabledAutoSendRtpVideo}');
    debugPrint('audioCodecs: ${configs.audioCodecs}');
    debugPrint('videoCodecs: ${configs.videoCodecs}');

    setState(() {
      _configs = configs;
    });
  }

  void updateConfigs() async {
    SipWrapper.wrapper.setConfigs(_configs);
  }
  
  void testFun() {
    SipWrapper.wrapper.hold();

    SipWrapper.wrapper.holdStateListener = HoldStateListener(onHoldState: (state) {
      switch(state) {
        case HoldState.ACTIVE:
          // TODO
          break;
        case HoldState.LOCAL_HOLD:
          // TODO
          break;
        case HoldState.REMOTE_HOLD:
          // TODO
          break;
      }
    });

    SipWrapper.wrapper.enableSpeaker(true);

    SipWrapper.wrapper.mute(true);

    SipWrapper.wrapper.startRecord();

    SipWrapper.wrapper.stopRecord();

    SipWrapper.wrapper.transferCall("123");
  }

}

class LoadingDialog {
  AlertDialog? dialog;

  show(BuildContext c) {
    debugPrint("LoadingDialog show");
    dialog = AlertDialog(title: Text("Loading..."));
    return showDialog(
        context: c,
        barrierDismissible: false,
        builder: (BuildContext c) {
          return dialog!;
        });
  }

  hide(BuildContext c) {
    if (dialog != null) {
      Navigator.pop(c);
      dialog = null;
    }
  }
}
