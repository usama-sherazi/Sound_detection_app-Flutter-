import 'package:flutter/material.dart';
import 'sound_detection.dart';
import 'package:huawei_ml_language/huawei_ml_language.dart';
class Homepage extends StatelessWidget{
  const Homepage({super.key});



  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: 'Sound Detection App',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue
      ),
      home: const SoundDetection(),
    );
  }
}
