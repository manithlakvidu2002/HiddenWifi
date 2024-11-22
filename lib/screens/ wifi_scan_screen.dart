// ignore: file_names
import 'package:esp32/services/wifi_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';

class WifiScanScreen extends StatefulWidget {
  const WifiScanScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WifiScanScreenState createState() => _WifiScanScreenState();
}

class _WifiScanScreenState extends State<WifiScanScreen> {
  // ignore: deprecated_member_use
  List<WifiNetwork> _wifiList = [];
  String? _selectedSsid;
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool hidden = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    bool permissionsGranted = await WifiService.requestPermissions();
    if (permissionsGranted) {
      _scanWifi();
    } else {
      if (kDebugMode) {
        print('Location permission denied');
      }
    }
  }

  Future<void> _scanWifi() async {
    // ignore: deprecated_member_use
    List<WifiNetwork> networks = await WifiService.scanWifi();
    setState(() {
      _wifiList = networks;
    });
  }

  // ignore: deprecated_member_use
  void _showPasswordDialog(WifiNetwork? network) {
    _selectedSsid = network?.ssid;
    _ssidController.text = _selectedSsid ?? '';
    _passwordController.clear();
    hidden = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_selectedSsid != null
              ? 'Enter Password for $_selectedSsid'
              : 'Connect to Hidden Network'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedSsid == null)
                TextField(
                  controller: _ssidController,
                  decoration: const InputDecoration(
                    labelText: 'SSID',
                    hintText: 'Enter network name',
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter Wi-Fi password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              Row(
                children: [
                  Checkbox(
                    value: hidden,
                    onChanged: (bool? value) {
                      setState(() {
                        hidden = value ?? false;
                      });
                    },
                  ),
                  const Text('Hidden Network'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_ssidController.text.isNotEmpty) {
                  _connectToWifi();
                  Navigator.pop(context);
                } else {
                  if (kDebugMode) {
                    print('SSID cannot be empty');
                  }
                }
              },
              child: const Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _connectToWifi() async {
    String ssid = _ssidController.text;
    String password = _passwordController.text;

    bool isConnected = await WifiService.connectToWifi(
      // ignore: deprecated_member_use
      ssid as WifiNetwork, password,hidden,
    );

    if (isConnected) {
      if (kDebugMode) {
        print('Connected to $ssid');
      }
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to $ssid')),
      );
    } else {
      if (kDebugMode) {
        print('Failed to connect to $ssid');
      }
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to $ssid')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Wi-Fi Networks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPasswordDialog(null),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _scanWifi,
        child: _wifiList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _wifiList.length,
                itemBuilder: (context, index) {
                  // ignore: deprecated_member_use
                  WifiNetwork network = _wifiList[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12.0),
                      leading: Icon(
                        network.level != null && network.level! > -70
                            ? Icons.signal_wifi_4_bar
                            : Icons.signal_wifi_off,
                        color: network.level != null && network.level! > -70
                            ? Colors.green
                            : Colors.red,
                      ),
                      title: Text(
                        network.ssid ?? 'Unknown SSID',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Signal Strength: ${network.level} dBm'),
                      onTap: () => _showPasswordDialog(network),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
