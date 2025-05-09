import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:revengi/dio.dart';
import 'package:revengi/screens/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RevEngi App',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
