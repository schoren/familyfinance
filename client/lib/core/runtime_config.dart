import 'package:flutter/foundation.dart';
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
    if (testMode) return 'test-google-client-id.apps.googleusercontent.com';
    final runtimeValue = getRuntimeGoogleClientId();
    if (runtimeValue != null && runtimeValue.isNotEmpty && !runtimeValue.contains('GOOGLE_CLIENT_ID_PLACEHOLD')) {
      return runtimeValue;
    }
    const envValue = String.fromEnvironment('GOOGLE_CLIENT_ID');
    if (envValue.isNotEmpty && !envValue.contains('GOOGLE_CLIENT_ID_PLACEHOLD')) return envValue;
    
    // Fallback for any kind of test/debug environment on web where Client ID is missing
    return 'test-google-client-id.apps.googleusercontent.com';
  }

  static bool get testMode {
    final runtimeValue = getRuntimeTestMode();
    // If runtimeValue is true, we are definitely in test mode.
    // If it's false, it might be the literal 'false' or the placeholder "TEST_MODE_PLACEHOLD".
    // We should only trust it if it's explicitly true or if we are NOT in a web environment where placeholders exist.
    if (runtimeValue == true) return true;
    
    const envVal = String.fromEnvironment('TEST_MODE');
    final boolVal = const bool.fromEnvironment('TEST_MODE', defaultValue: false);
    final result = envVal == 'true' || boolVal;
    
    // ignore: avoid_print
    if (kDebugMode) print('RuntimeConfig: testMode evaluated to $result (envVal: $envVal, boolVal: $boolVal, runtime: $runtimeValue)');
    
    return result;
  }

  static String? get testHouseholdId {
    final runtimeValue = getRuntimeTestHouseholdId();
    if (runtimeValue != null && runtimeValue.isNotEmpty && !runtimeValue.contains('TEST_HOUSEHOLD_ID_PLACEHOLD')) {
      return runtimeValue;
    }
    const envValue = String.fromEnvironment('TEST_HOUSEHOLD_ID');
    return (envValue.isNotEmpty && !envValue.contains('TEST_HOUSEHOLD_ID_PLACEHOLD')) ? envValue : null;
  }

  static String get appVersion {
    return const String.fromEnvironment('APP_VERSION', defaultValue: 'local-dev');
  }
}
