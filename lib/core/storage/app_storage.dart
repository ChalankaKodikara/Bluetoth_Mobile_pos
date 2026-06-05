import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  AppStorage._();

  static const String accessTokenKey = 'access_token';
  static const String userKey = 'user_data';
  static const String usersKey = 'users_data';
  static const String printerMacKey = 'printer_mac';

  static Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(accessTokenKey, token);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(accessTokenKey);
  }

  static Future<void> saveUser(String userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, userJson);
  }

  static Future<String?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userKey);
  }

  static Future<void> saveUsers(String usersJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(usersKey, usersJson);
  }

  static Future<String?> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(usersKey);
  }

  static Future<void> savePrinterMac(String mac) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(printerMacKey, mac);
  }

  static Future<String?> getPrinterMac() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(printerMacKey);
  }

  static Future<void> clearAuthOnly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(accessTokenKey);
    await prefs.remove(userKey);
    await prefs.remove(usersKey);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
