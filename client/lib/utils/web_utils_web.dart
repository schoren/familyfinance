// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js; // ignore: deprecated_member_use
import 'package:flutter_web_plugins/url_strategy.dart';

void hideSplash() {
  try {
    js.context.callMethod('hideSplash');
  } catch (e) {
    // Ignore if not available
  }
}

void forceNumericInput() {
  try {
    js.context.callMethod('forceNumericInput');
  } catch (e) {
    // Ignore
  }
}

void configureUrlStrategy() {
  usePathUrlStrategy();
}
