import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/api/api_client.dart';
import '../../core/security/secure_auth_service.dart';
import '../../core/storage/app_storage.dart';
import '../dashboard/dashboard_page.dart';
import 'login_page.dart';

class AuthController extends GetxController {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final isPasswordHidden = true.obs;
  final isLoading = false.obs;
  final isBiometricLoading = false.obs;
  final hasSavedLogin = false.obs;
  final savedUsername = ''.obs;

  @override
  void onInit() {
    super.onInit();
    checkSavedLogin();
  }

  Future<void> checkSavedLogin() async {
    hasSavedLogin.value = await SecureAuthService.hasSavedLogin();
    savedUsername.value = await SecureAuthService.getUsername() ?? '';
  }

  Future<void> loginWithDeviceAuth() async {
    try {
      isBiometricLoading.value = true;

      final token = await SecureAuthService.getToken();

      if (token == null || token.isEmpty) {
        Get.snackbar('Login Required', 'Please login first');
        return;
      }

      final success = await SecureAuthService.authenticate();

      if (success) {
        Get.offAll(() => const DashboardPage());
      } else {
        Get.snackbar('Failed', 'Device authentication failed');
      }
    } finally {
      isBiometricLoading.value = false;
    }
  }

  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      Get.snackbar('Required', 'Username and password are required');
      return;
    }

    try {
      isLoading.value = true;

      final response = await ApiClient.dio.post(
        '/auth/signin',
        data: {'username': username, 'password': password},
      );

      final data = response.data;

      final token =
          data['accessToken'] ??
          data['token'] ??
          data['access_token'] ??
          data['data']?['accessToken'] ??
          data['data']?['token'];

      if (token == null || token.toString().isEmpty) {
        Get.snackbar('Login Failed', 'Token not found in response');
        return;
      }

      await AppStorage.saveAccessToken(token.toString());

      await SecureAuthService.saveLogin(
        token: token.toString(),
        username: username,
      );

      Get.offAll(() => const DashboardPage());
    } catch (e) {
      Get.snackbar('Login Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await SecureAuthService.clearLogin();
    await AppStorage.clearAll();

    Get.offAll(() => const LoginPage());
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
