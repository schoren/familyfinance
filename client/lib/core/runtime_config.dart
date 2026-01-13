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
}
