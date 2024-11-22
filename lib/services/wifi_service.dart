import 'package:wifi_iot/wifi_iot.dart';

class WifiService {
  // Request location permissions to scan Wi-Fi
  static Future<bool> requestPermissions() async {
    // Implement permission request logic if necessary
    return true;  // Assuming permissions are granted for simplicity
  }

  // Scan for available Wi-Fi networks
  static Future<List<WifiNetwork>> scanWifi() async {
    bool isEnabled = await WiFiForIoTPlugin.isEnabled();
    if (!isEnabled) {
      await WiFiForIoTPlugin.setEnabled(true);
    }

    return await WiFiForIoTPlugin.loadWifiList();
  }

  // Connect to the selected network using SSID and user-provided password
  static Future<bool> connectToWifi(WifiNetwork network, String password, bool hidden) async {
    bool isConnected = await WiFiForIoTPlugin.connect(
      network.ssid ?? '',
      password: password,
      joinOnce: true,
      isHidden: hidden,
      security: NetworkSecurity.WPA,
    );
    return isConnected;
  }
}
