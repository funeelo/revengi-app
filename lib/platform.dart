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
