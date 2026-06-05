import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../storage/app_storage.dart';

class ApiClient {
  static const String baseUrl = 'https://dev-back-rms.talentfort.live/api/v1';

  static late Dio dio;
  static late PersistCookieJar cookieJar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();

    cookieJar = PersistCookieJar(storage: FileStorage('${dir.path}/.cookies'));

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        extra: {'withCredentials': true},
      ),
    );

    dio.interceptors.add(CookieManager(cookieJar));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AppStorage.getAccessToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await refreshToken();

            if (refreshed) {
              final newToken = await AppStorage.getAccessToken();

              final requestOptions = error.requestOptions;
              requestOptions.headers['Authorization'] = 'Bearer $newToken';

              final retryResponse = await dio.fetch(requestOptions);
              return handler.resolve(retryResponse);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  static Future<bool> refreshToken() async {
    try {
      final response = await dio.post('/auth/refresh-token');

      final data = response.data;

      final accessToken =
          data['accessToken'] ??
          data['token'] ??
          data['access_token'] ??
          data['data']?['accessToken'] ??
          data['data']?['token'];

      if (accessToken != null && accessToken.toString().isNotEmpty) {
        await AppStorage.saveAccessToken(accessToken.toString());
        return true;
      }

      return false;
    } catch (_) {
      await AppStorage.clearAll();
      await clearCookies();
      return false;
    }
  }

  static Future<void> clearCookies() async {
    await cookieJar.deleteAll();
  }
}
