import 'runtime_config_stub.dart' if (dart.library.html) 'runtime_config_web.dart' if (dart.library.js) 'runtime_config_web.dart';

class RuntimeConfig {
  static String get apiUrl {
    final runtimeValue = getRuntimeApiUrl();
    if (runtimeValue != null && runtimeValue.isNotEmpty && !runtimeValue.contains('API_URL_PLACEHOLD')) {
      return runtimeValue;
    }
    return const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8090');
  }

  static String? get googleClientId {
    final runtimeValue = getRuntimeGoogleClientId();
    if (runtimeValue != null && runtimeValue.isNotEmpty && !runtimeValue.contains('GOOGLE_CLIENT_ID_PLACEHOLD')) {
      return runtimeValue;
    }
    const envValue = String.fromEnvironment('GOOGLE_CLIENT_ID');
    return envValue.isNotEmpty ? envValue : null;
  }

  static bool get testMode {
    final runtimeValue = getRuntimeTestMode();
    if (runtimeValue != null) return runtimeValue;
    return const bool.fromEnvironment('TEST_MODE', defaultValue: false);
  }

  static String? get testHouseholdId {
    final runtimeValue = getRuntimeTestHouseholdId();
    if (runtimeValue != null) return runtimeValue;
    const envValue = String.fromEnvironment('TEST_HOUSEHOLD_ID');
    return envValue.isNotEmpty ? envValue : null;
  }

  static String get appVersion {
    return const String.fromEnvironment('APP_VERSION', defaultValue: 'local-dev');
  }
}
