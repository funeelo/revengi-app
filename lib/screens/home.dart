import 'package:flutter/material.dart';
import 'package:revengi/platform.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:revengi/dio.dart';
import 'package:revengi/screens/user.dart';
import 'package:revengi/cards.dart';
import 'package:revengi/screens/mthook/mthook.dart';
import 'package:revengi/screens/blutter/blutter.dart';
import 'package:revengi/screens/dexrepair/dexrepair.dart';
import 'package:revengi/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:revengi/screens/smali_grammar.dart';

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

  Future<void> _showSmaliGrammarDialog(BuildContext context) async {
    if (context.mounted) {
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Row(
                children: [
                  const Text('Smali Grammar'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.8,
                child: const SmaliInstructionDialog(),
              ),
            ),
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color:
                    Brightness.dark == Theme.of(context).brightness
                        ? Colors.black
                        : Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/dark_splash.png'
                        : 'assets/light_splash.png',
                    height: 90,
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final brightness = Theme.of(context).brightness;
                      return Text(
                        'RevEngi Tools',
                        style: TextStyle(
                          color:
                              brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                          fontSize: 24,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                context.watch<ThemeProvider>().themeMode == ThemeMode.system
                    ? Icons.brightness_auto
                    : context.watch<ThemeProvider>().themeMode ==
                        ThemeMode.light
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              title: Text(
                'Theme: ${context.watch<ThemeProvider>().themeMode == ThemeMode.system
                    ? 'System'
                    : context.watch<ThemeProvider>().themeMode == ThemeMode.light
                    ? 'Light'
                    : 'Dark'}',
              ),
              onTap: () {
                context.read<ThemeProvider>().toggleTheme();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Smali Grammar'),
              onTap: () {
                Navigator.pop(context);
                _showSmaliGrammarDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'RevEngi',
                  applicationVersion: '1.0.0',
                  applicationIcon: Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/dark_splash.png'
                        : 'assets/light_splash.png',
                    height: 50,
                  ),
                  children: [
                    const Text('A collection of reverse engineering tools.'),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      icon: const Icon(Icons.star),
                      label: const Text('Star on GitHub'),
                      onPressed:
                          () => launchUrl(
                            Uri.parse(
                              'https://github.com/RevEngiSquad/revengi-app',
                            ),
                          ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
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
            description: 'Analyze Flutter libs',
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
