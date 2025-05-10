import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

bool isAndroid() {
  return Platform.isAndroid;
}

bool isIOS() {
  return Platform.isIOS;
}

bool isWindows() {
  return Platform.isWindows;
}

bool isLinux() {
  return Platform.isLinux;
}

bool isWeb() {
  return kIsWeb;
}

String getDownloadsDirectory() {
  if (isAndroid()) {
    return '/storage/emulated/0/Download/RevEngi';
  } else if (isIOS()) {
    return '/Users/${Platform.environment['USER']}/Downloads/RevEngi';
  } else if (isWindows()) {
    return '${Platform.environment['USERPROFILE']}\\Downloads\\RevEngi';
  } else if (isLinux()) {
    return '/home/${Platform.environment['USER']}/Downloads/RevEngi';
  } else {
    throw UnsupportedError('Unsupported platform');
  }
}
