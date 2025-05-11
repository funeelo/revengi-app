import 'package:flutter/material.dart';
import 'package:revengi/platform.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:revengi/dio.dart';
import 'package:revengi/screens/user.dart';
import 'package:revengi/cards.dart';
import 'package:revengi/screens/mthook/mthook.dart';
import 'package:revengi/screens/blutter/blutter.dart';
import 'package:revengi/screens/dexrepair/dexrepair.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    dio.options.headers.remove('X-API-Key');

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RevEngi Tools'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount:
            isWeb()
                ? 4
                : isWindows()
                ? 4
                : isLinux()
                ? 4
                : 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          AnalysisCard(
            title: 'JNI Analysis',
            icon: Icons.android,
            description: 'Find JNI signatures in APK',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JniAnalysisScreen(),
                  ),
                ),
          ),
          AnalysisCard(
            title: 'Flutter Analysis',
            icon: Icons.flutter_dash,
            description: 'Analyze Flutter libraries',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FlutterAnalysisScreen(),
                  ),
                ),
          ),
          AnalysisCard(
            title: 'Blutter',
            icon: Icons.build,
            description: 'Flutter binary analysis tool',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BlutterAnalysisScreen(),
                  ),
                ),
          ),
          AnalysisCard(
            title: 'MT Hook',
            icon: Icons.book,
            description: 'Generate MT Enhanced Hooks',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MTHookAnalysisScreen(),
                  ),
                ),
          ),
          AnalysisCard(
            title: 'Dex Repair',
            icon: Icons.auto_fix_high,
            description: 'Repair DEX files',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DexRepairScreen(),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
