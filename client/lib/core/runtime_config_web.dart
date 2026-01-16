import 'dart:js' as js;

String? getRuntimeApiUrl() {
  try {
    final config = js.context['FF_CONFIG'];
    if (config != null) {
      return config['API_URL'] as String?;
    }
  } catch (e) {
    // Fallback if JS interop fails
  }
  return null;
}

String? getRuntimeGoogleClientId() {
  try {
    final config = js.context['FF_CONFIG'];
    if (config != null) {
      return config['GOOGLE_CLIENT_ID'] as String?;
    }
  } catch (e) {
    // Fallback if JS interop fails
  }
  return null;
}

bool? getRuntimeTestMode() {
  try {
    final jsConf = js.context['FF_CONFIG'];
    if (jsConf == null) return null;
    
    // In Flutter Web, js.context['FF_CONFIG'] might return a Map or a JsObject
    // We try to access the property safely.
    var val;
    if (jsConf is Map) {
      val = jsConf['TEST_MODE'];
    } else {
      val = jsConf['TEST_MODE'];
    }

    if (val == null) return null;
    if (val is bool) return val;
    if (val is String) return val.toLowerCase() == 'true';
  } catch (e) {
    print('[Dart SDK] Error reading TEST_MODE: $e');
  }
  return null;
}

String? getRuntimeTestHouseholdId() {
  try {
    final jsConf = js.context['FF_CONFIG'];
    if (jsConf == null) return null;
    return jsConf['TEST_HOUSEHOLD_ID'] as String?;
  } catch (e) {
    return null;
  }
}
