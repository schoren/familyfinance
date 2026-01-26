// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js; // ignore: deprecated_member_use
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

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
    dynamic val;
    if (jsConf is Map) {
      val = jsConf['TEST_MODE'];
    } else {
      val = jsConf['TEST_MODE'];
    }

    if (val == null) return null;
    if (val is bool) return val;
    if (val is String) return val.toLowerCase() == 'true';
  } catch (e) {
    debugPrint('[Dart SDK] Error reading TEST_MODE: $e');
  }
  return null;
}

bool getForceShowLogin() {
  try {
    final uri = Uri.parse(html.window.location.href);
    return uri.queryParameters['forceShowLogin'] == 'true';
  } catch (e) {
    return false;
  }
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
