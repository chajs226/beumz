import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:io' if (dart.library.html) 'dart:html' as html;

// 웹에서만 import
// ignore: uri_does_not_exist
import 'package:hive_flutter/hive_flutter.dart' if (dart.library.html) 'package:hive/hive.dart';

class UserIdUtil {
  static const String _userBox = 'userBox';
  static const String _keyDeviceId = 'deviceId';
  static const String _keyUserName = 'userName';

  static Future<void> initHive() async {
    if (kIsWeb) {
      await Hive.initFlutter();
    } else {
      final dir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(dir.path);
    }
    await Hive.openBox(_userBox);
  }

  static Future<void> saveUserName(String name) async {
    final box = Hive.box(_userBox);
    await box.put(_keyUserName, name);
  }

  static Future<String?> getUserName() async {
    final box = Hive.box(_userBox);
    return box.get(_keyUserName);
  }

  static Future<void> ensureDeviceId() async {
    final box = Hive.box(_userBox);
    if (box.get(_keyDeviceId) != null) return;
    // 실제 디바이스 ID는 플랫폼별로 구현 필요. 임시 UUID 사용
    final id = _generateFakeDeviceId();
    await box.put(_keyDeviceId, id);
  }

  static String _generateFakeDeviceId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static Future<String?> getDeviceId() async {
    final box = Hive.box(_userBox);
    return box.get(_keyDeviceId);
  }
} 