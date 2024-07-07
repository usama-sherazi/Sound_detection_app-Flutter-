import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sound_detection_app/Settings.dart'; // Adjust the path as necessary

class SoundDetection extends StatefulWidget {
  const SoundDetection({super.key});

  @override
  _SoundDetectionState createState() => _SoundDetectionState();
}

class _SoundDetectionState extends State<SoundDetection> {
  bool _cryingBaby = false;
  bool _shoutingPet = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cryingBaby = prefs.getBool('cryingBaby') ?? false;
      _shoutingPet = prefs.getBool('Shouting-pet') ?? false;
    });
  }

  void _openSettingsOverlay(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => const Settings(),
      isScrollControlled: true,
    );

    // Reload preferences and update state after settings modal closes
    _loadPreferences();
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
                Icon(Icons.earbuds_sharp ,size: 40,),
                SizedBox(width: 10.0),
                Text(
                  'Listening for sounds...',
                  style: TextStyle(fontSize: 24.0,fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/cryingbaby.svg',
                  width: 1000.0,
                  height: 50.0,
                ),
                const SizedBox(width: 10.0),
                Text(
                  _cryingBaby
                      ? 'Crying Baby setting is ON'
                      : 'Crying Baby setting is OFF',
                  style: const TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _shoutingPet ? Icons.pets : Icons.pets_outlined,
                  size: 30.0,
                  color: _shoutingPet ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 10.0),
                Text(
                  _shoutingPet
                      ? 'Shouting Pet setting is ON'
                      : 'Shouting Pet setting is OFF',
                  style: const TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
