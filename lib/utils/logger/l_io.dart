import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:l/l.dart';
import 'package:path_provider/path_provider.dart';
import 'package:revengi/utils/platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initLogger() async {
  final prefs = await SharedPreferences.getInstance();
  final logEnabled = prefs.getBool('logEnabled') ?? false;
  if (!logEnabled) return;

  final dir = await getExternalStorageDirectory();
  final logFile = File('${dir!.path}/logs.txt');

  if (!await logFile.exists()) {
    await logFile.create(recursive: true);
  }

  String? fileLogger(LogMessage event) {
    final logEntry = '''
Timestamp: ${event.timestamp.toUtc().toIso8601String()}
Level: ${event.level.toString()}
Message: ${event.message.toString()}
${event is LogMessageError ? 'Stack Trace: ${event.stackTrace.toString()}' : ''}
''';
    logFile.writeAsStringSync(
      '$logEntry\n',
      mode: FileMode.append,
      flush: true,
    );
    return null;
  }

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
      overrideOutput: fileLogger,
      outputInRelease: true,
      printColors: false,
      output: LogOutput.platform,
    ),
  );
}
