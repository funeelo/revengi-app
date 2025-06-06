import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

late Dio dio;

Future<String> getApiUrl() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('apiUrl') ?? 'https://api.revengi.in';
}

Future<void> initializeDio() async {
  dio = Dio(
    BaseOptions(
      baseUrl: await getApiUrl(),
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    ),
  );
}
