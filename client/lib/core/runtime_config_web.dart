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
