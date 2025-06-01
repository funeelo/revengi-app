import 'package:flutter/foundation.dart'
    show LicenseRegistry, LicenseEntryWithLineBreaks;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:revengi/utils/platform.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:revengi/utils/dio.dart';
import 'package:revengi/screens/user.dart';
import 'package:revengi/utils/cards.dart';
import 'package:revengi/screens/mthook/mthook.dart';
import 'package:revengi/screens/blutter/blutter.dart';
import 'package:revengi/screens/dexrepair/dexrepair.dart';
import 'package:revengi/utils/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:revengi/screens/smali_grammar.dart';
import 'package:revengi/screens/profile_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:revengi/screens/jni_analysis.dart';
import 'package:revengi/screens/flutter_analysis.dart';

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

  void addLicenses() {
    final licenses = {
      'revengi': 'assets/licenses/revengi.txt',
      'sigtool': 'assets/licenses/sigtool.txt',
      'smalig': 'assets/licenses/smalig.txt',
      'blutter': 'assets/licenses/blutter.txt',
    };

    for (var entry in licenses.entries) {
      LicenseRegistry.addLicense(() async* {
        yield LicenseEntryWithLineBreaks([
          entry.key,
        ], await rootBundle.loadString(entry.value));
      });
    }
  }

  Future<void> _requestPermissions() async {
    int sdkVersion = await DeviceInfo.getSdkVersion();
    if (sdkVersion < 29) {
      if (await Permission.storage.isGranted) {
        return;
      }

      if (await Permission.storage.isPermanentlyDenied) {
        openAppSettings();
        return;
      }

      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    addLicenses();
    if (!isWeb() && isAndroid()) _requestPermissions();
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
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
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
                  applicationVersion: '1.0.7',
                  applicationLegalese: '© ${DateTime.now().year} RevEngi',
                  applicationIcon: Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/dark_splash.png'
                        : 'assets/light_splash.png',
                    height: 50,
                  ),
                  children: [
                    const Text('\nA collection of reverse engineering tools.'),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              mainAxisExtent: 170,
            ),
            itemCount: 5,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return AnalysisCard(
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
                  );
                case 1:
                  return AnalysisCard(
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
                  );
                case 2:
                  return AnalysisCard(
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
                  );
                case 3:
                  return AnalysisCard(
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
                  );
                case 4:
                  return AnalysisCard(
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
                  );
                default:
                  return const SizedBox.shrink();
              }
            },
          );
        },
      ),
    );
  }
}
