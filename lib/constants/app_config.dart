import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _devApiUrl = 'http://127.0.0.1:8000/api';
  static const String _androidDevApiUrl = 'http://10.0.2.2:8000/api';
  static const String _prodApiUrl = 'https://api.exquillermember.com/api';

  // Environment flags
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static const bool isDevelopment = !isProduction;

  // API Base URL with environment and platform detection
  static String get apiBaseUrl {
    if (isProduction) {
      return _prodApiUrl;
    }

    // Development environment
    if (kIsWeb) {
      return _devApiUrl;
    } else if (Platform.isAndroid) {
      return _androidDevApiUrl;
    } else {
      return _devApiUrl;
    }
  }

  // Thai Address Service Base URL
  static String get thaiAddressApiUrl {
    if (isProduction) {
      return 'https://api.exquillermember.com/test/address';
    }

    // Development environment
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/test/address';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/test/address';
    } else {
      return 'http://127.0.0.1:8000/test/address';
    }
  }

  // App Information
  static const String appName = 'Clinic Membership App';
  static const String version = '1.0.0';

  // Storage Base URL for images and files
  static String get storageBaseUrl {
    if (isProduction) {
      return 'https://api.exquillermember.com/storage';
    }

    // Development environment
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/storage';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/storage';
    } else {
      return 'http://127.0.0.1:8000/storage';
    }
  }

  // Debug settings
  static bool get enableDebugPrint => isDevelopment;
}