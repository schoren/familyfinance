import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class IOSKeyboardFix {
  static void prime() {
    try {
      final hack = js.context['ios_keyboard_hack'];
      if (hack != null) {
        hack.callMethod('prime');
      }
    } catch (e) {
      debugPrint('Error priming iOS keyboard: $e');
    }
  }

  static void stop() {
    try {
      final hack = js.context['ios_keyboard_hack'];
      if (hack != null) {
        hack.callMethod('stop');
      }
    } catch (e) {
      debugPrint('Error stopping iOS keyboard fight: $e');
    }
  }
}
