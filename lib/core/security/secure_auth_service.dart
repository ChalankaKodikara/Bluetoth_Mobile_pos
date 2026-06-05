import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class SecureAuthService {
  SecureAuthService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final LocalAuthentication _auth = LocalAuthentication();

  static const String _accessTokenKey = 'access_token';
  static const String _usernameKey = 'saved_username';

  static Future<void> saveLogin({
    required String token,
    required String username,
  }) async {
    await _storage.write(key: _accessTokenKey, value: token);
    await _storage.write(key: _usernameKey, value: username);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getUsername() async {
    return _storage.read(key: _usernameKey);
  }

  static Future<bool> hasSavedLogin() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearLogin() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _usernameKey);
  }

  static Future<bool> authenticate() async {
    try {
      final isSupported = await _auth.isDeviceSupported();

      if (!isSupported) return false;

      return await _auth.authenticate(
        localizedReason: 'Unlock Synera RMS',
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Synera RMS',
            cancelButton: 'Cancel',
          ),
          IOSAuthMessages(cancelButton: 'Cancel'),
        ],
      );
    } catch (_) {
      return false;
    }
  }
}
