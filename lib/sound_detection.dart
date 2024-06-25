import 'package:flutter/material.dart';
import 'package:huawei_ml_language/huawei_ml_language.dart';

class SoundDetection extends StatefulWidget {
  const SoundDetection({super.key});  // Use the correct constructor

  @override
  _SoundDetectionState createState() => _SoundDetectionState();
}

class _SoundDetectionState extends State<SoundDetection> {
  late MLSoundDetector _detector;

  @override
  void initState() {
    super.initState();
    _detector = MLSoundDetector();
    _detector.setSoundDetectListener(onDetection);
    _detector.start();
  }

  void onDetection({int? result, int? errCode}) {
    if (errCode != null) {
      print('Error detected: $errCode');
    } else if (result != null) {
      print('Sound detected with result: $result');
      // Handle the sound detection result
    }
  }

  @override
  void dispose() {
    _detector.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Detector App'),
      ),
      body: const Center(
        child: Text('Listening for sounds...'),
      ),
    );
  }
}
