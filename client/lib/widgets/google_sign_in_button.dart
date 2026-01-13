import 'package:flutter/material.dart';
import 'google_sign_in_button_stub.dart'
    if (dart.library.js_interop) 'google_sign_in_button_web.dart';

Widget buildGoogleSignInButton({VoidCallback? onPressed}) {
  return buildButton(onPressed: onPressed);
}
