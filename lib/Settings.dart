import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  // Variables to store the shared preference data
  bool _cryingBaby = false;
  bool _shoutingPet = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // Method to load the shared preference data
  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cryingBaby = prefs.getBool('cryingBaby') ?? false;
      _shoutingPet = prefs.getBool('Shouting-pet') ?? false;
    });
  }

  // Method to update shared preferences and state when a switch is toggled
  void _updatePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
    setState(() {
      if (key == 'cryingBaby') {
        _cryingBaby = value;
      } else if (key == 'Shouting-pet') {
        _shoutingPet = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 90,
          title: const Text('Settings'),
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 5.0),
                borderRadius: BorderRadius.circular(30.0),
              ),
              child: SwitchListTile(
                title: const Text('Crying Baby'),
                secondary: SvgPicture.asset(
                  'assets/icons/cryingbaby.svg',
                  width: 30.0,
                  height: 30.0,
                ),
                value: _cryingBaby,
                onChanged: (value) {
                  _updatePreference('cryingBaby', value);
                },
              ),
            ),
            const SizedBox(height: 50.0), // Adjusted space between widgets
            Container(
              width: 1000,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 5.0),
                borderRadius: BorderRadius.circular(30.0),
              ),
              child: SwitchListTile(
                title: const Text('Shouting-pet'),
                secondary: const Icon(Icons.pets, size: 30),
                value: _shoutingPet,
                onChanged: (value) {
                  _updatePreference('Shouting-pet', value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
