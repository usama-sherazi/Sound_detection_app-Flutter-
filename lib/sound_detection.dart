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
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/cryingbaby.svg',
                        width: 30.0,
                        height: 60.0,
                      ),
                      const SizedBox(width: 10.0),
                      Text(
                        _cryingBaby
                            ? 'Detecting crying Baby sound'
                            : 'Not detecting  Baby sound',
                        style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
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
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _shoutingPet ? Icons.pets : Icons.pets_outlined,
                        size: 40.0,
                        color: _shoutingPet ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 2.0),
                      Text(
                        _shoutingPet
                            ? 'Detecting Shouting Pet sound'
                            : 'Not DetectingShouting Pet sound',
                        style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                    ],
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
