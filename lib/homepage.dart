import 'package:flutter/material.dart';
import 'package:sound_detection_app/sound_detection.dart';

class Homepage extends StatelessWidget{
  const Homepage({super.key});







  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sound Detection App',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue
      ),
      home: const SoundDetection()
    );
  }
}
