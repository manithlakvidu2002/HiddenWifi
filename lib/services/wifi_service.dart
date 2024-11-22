import 'package:wifi_iot/wifi_iot.dart';

class WifiService {
  static Future<bool> requestPermissions() async {
    return true;
  }

  // ignore: deprecated_member_use
  static Future<List<WifiNetwork>> scanWifi() async {
    bool isEnabled = await WiFiForIoTPlugin.isEnabled();
    if (!isEnabled) {
      await WiFiForIoTPlugin.setEnabled(true);
    }

    // ignore: deprecated_member_use
    return await WiFiForIoTPlugin.loadWifiList();
  }

  // ignore: deprecated_member_use
  static Future<bool> connectToWifi(
      // ignore: deprecated_member_use
      String ssid,
      String password,
      bool hidden) async {
    bool isConnected = await WiFiForIoTPlugin.connect(
      // network.ssid ?? '',
      ssid = ssid,
      password: password,
      joinOnce: true,
      isHidden: hidden,
      security: NetworkSecurity.WPA,
    );
    return isConnected;
  }

  static Future<bool> disconnectWifi() {
    return WiFiForIoTPlugin.disconnect();
  }
}
