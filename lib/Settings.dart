import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _cryingBaby = false;
  bool _shoutingPet = false;
  bool _laughing = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();
  final TextEditingController _phoneCryingBabyController = TextEditingController();
  final TextEditingController _phoneShoutingPetController = TextEditingController();
  final TextEditingController _phoneLaughingController = TextEditingController();

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
      _laughing = prefs.getBool('laughing') ?? false;
      _usernameController.text = prefs.getString('username') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
      _domainController.text = prefs.getString('domain') ?? '';
      _phoneCryingBabyController.text = prefs.getString('phoneCryingBaby') ?? '';
      _phoneShoutingPetController.text = prefs.getString('phoneShoutingPet') ?? '';
      _phoneLaughingController.text = prefs.getString('phoneLaughing') ?? '';
    });
  }

  void _updatePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
    setState(() {
      if (key == 'cryingBaby') {
        _cryingBaby = value;
      } else if (key == 'Shouting-pet') {
        _shoutingPet = value;
      } else if (key == 'laughing') {
        _laughing = value;
      }
    });
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', _usernameController.text);
      await prefs.setString('password', _passwordController.text);
      await prefs.setString('domain', _domainController.text);
      await prefs.setString('phoneCryingBaby', _phoneCryingBabyController.text);
      await prefs.setString('phoneShoutingPet', _phoneShoutingPetController.text);
      await prefs.setString('phoneLaughing', _phoneLaughingController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text('Settings'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Username TextFormField
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 3.0),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    } else if (value.length != 3) {
                      return 'Username must be exactly 3 characters';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 10.0),

              // Password TextFormField
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 3.0),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: InputBorder.none,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    } else if (value.length < 4) {
                      return 'Password must be exactly 4 characters';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 10.0),

              // Domain TextFormField
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 3.0),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: TextFormField(
                  controller: _domainController,
                  decoration: const InputDecoration(
                    labelText: 'Domain',
                    prefixIcon: Icon(Icons.domain),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a domain';
                    } else if (value.length == 16) {
                      return 'Domain must be exactly 14 characters';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 10.0),

              // Crying Baby Container
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 3.0),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/cryingbaby.svg',
                      width: 24.0,
                      height: 24.0,
                    ),
                    const SizedBox(width: 10.0),
                    const Text('Crying Baby'),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCryingBabyController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Exten',
                          prefixIcon: Icon(Icons.phone),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Switch(
                      value: _cryingBaby,
                      onChanged: (value) {
                        _updatePreference('cryingBaby', value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10.0),

              // Shouting Pet Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 3.0),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pets, size: 24),
                    const SizedBox(width: 10.0),
                    const Text('Shouting-pet'),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneShoutingPetController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Exten',
                          prefixIcon: Icon(Icons.phone),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Switch(
                      value: _shoutingPet,
                      onChanged: (value) {
                        _updatePreference('Shouting-pet', value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10.0),

              // Laughing Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 3.0),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_emotions, size: 24),
                    const SizedBox(width: 20.0),
                    const Text('Laughing'),
                    const SizedBox(width: 20.0),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneLaughingController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Exten',
                          prefixIcon: Icon(Icons.phone),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Switch(
                      value: _laughing,
                      onChanged: (value) {
                        _updatePreference('laughing', value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // Save Button
              Center(
                child: ElevatedButton(
                  onPressed: _handleSave,
                  child: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
