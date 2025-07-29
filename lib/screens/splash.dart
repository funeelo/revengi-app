import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:revengi/screens/home.dart';
import 'package:revengi/screens/user.dart';
import 'package:revengi/utils/dio.dart';
import 'package:revengi/utils/platform.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final String? username = prefs.getString('username');
    final String? apiKey = prefs.getString('apiKey');

    if (isLoggedIn && username != null) {
      if (apiKey != null) {
        dio.options.headers['X-API-Key'] = apiKey;
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          Brightness.dark == Theme.of(context).brightness
              ? Colors.black
              : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              isDarkMode ? 'assets/dark_splash.png' : 'assets/light_splash.png',
              width:
                  isWeb()
                      ? MediaQuery.of(context).size.width * 0.4
                      : isWindows()
                      ? MediaQuery.of(context).size.width * 0.3
                      : isLinux()
                      ? MediaQuery.of(context).size.width * 0.3
                      : MediaQuery.of(context).size.width * 0.7,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              'Reverse Engineering Tools',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
