import 'package:esp32/services/wifi_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';

class WifiScanScreen extends StatefulWidget {
  const WifiScanScreen({super.key});

  @override
  _WifiScanScreenState createState() => _WifiScanScreenState();
}

class _WifiScanScreenState extends State<WifiScanScreen> {
  List<WifiNetwork> _wifiList = [];
  String? _connectedSsid;
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
    List<WifiNetwork> networks = await WifiService.scanWifi();
    setState(() {
      _wifiList = networks;
    });
  }

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
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Column(
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
                          setDialogState(() {
                            hidden = value ?? false;
                          });
                        },
                      ),
                      const Text('Hidden Network'),
                    ],
                  ),
                ],
              );
            },
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
      ssid,
      password,
      hidden,
    );

    if (isConnected) {
      setState(() {
        _connectedSsid = ssid;
      });
      if (kDebugMode) {
        print('Connected to $ssid');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to $ssid')),
      );
    } else {
      if (kDebugMode) {
        print('Failed to connect to $ssid');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to $ssid')),
      );
    }
  }

  Future<void> _disconnectFromWifi() async {
    bool isDisconnected = await WifiService.disconnectWifi();
    if (isDisconnected) {
      setState(() {
        _connectedSsid = null;
      });
      if (kDebugMode) {
        print('Disconnected from Wi-Fi');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disconnected from Wi-Fi')),
      );
    } else {
      if (kDebugMode) {
        print('Failed to disconnect');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to disconnect')),
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
                  WifiNetwork network = _wifiList[index];
                  bool isConnected = _connectedSsid == network.ssid;

                  Color signalColor = Colors.grey;
                  if (network.level != null) {
                    if (network.level! > -60) {
                      signalColor = Colors.green;
                    } else if (network.level! > -80) {
                      signalColor = Colors.amber;
                    } else {
                      signalColor = Colors.red;
                    }
                  }

                  return Card(
                    color: isConnected ? Colors.green[50] : null,
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12.0),
                      leading: Icon(
                        Icons.signal_wifi_4_bar,
                        color: isConnected ? Colors.green : signalColor,
                      ),
                      title: Text(
                        network.ssid ?? 'Unknown SSID',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isConnected ? Colors.green : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        'Signal Strength: ${network.level ?? 'Unknown'} dBm',
                        style: TextStyle(
                          color: isConnected ? Colors.green : Colors.black,
                        ),
                      ),
                      trailing: isConnected
                          ? ElevatedButton(
                              onPressed: _disconnectFromWifi,
                              child: const Text('Disconnect'),
                            )
                          : null,
                      onTap: () {
                        if (!isConnected) {
                          _showPasswordDialog(network);
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
