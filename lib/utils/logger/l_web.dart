import 'package:flutter/foundation.dart';
import 'package:l/l.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initLogger() async {
  final prefs = await SharedPreferences.getInstance();
  final logEnabled = prefs.getBool('logEnabled') ?? false;
  if (!logEnabled) return;

  l.capture<void>(
    () {
      final sourceFlutterError = FlutterError.onError;
      FlutterError.onError = (details) {
        l.e(details.exceptionAsString(), details.stack);
        sourceFlutterError?.call(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        l.e(error.toString(), stack);
        return true;
      };
    },
    LogOptions(
      handlePrint: true,
      outputInRelease: true,
      printColors: false,
      output: LogOutput.platform,
    ),
  );
}
