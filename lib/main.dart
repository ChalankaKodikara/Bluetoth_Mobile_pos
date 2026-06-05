import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'modules/auth/login_page.dart';
import 'modules/cart/cart_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  await ApiClient.init();

  Get.put<CartController>(CartController(), permanent: true);

  runApp(const SyneraRMSApp());
}

class SyneraRMSApp extends StatelessWidget {
  const SyneraRMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Synera RMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
      getPages: [GetPage(name: '/login', page: () => const LoginPage())],
    );
  }
}
