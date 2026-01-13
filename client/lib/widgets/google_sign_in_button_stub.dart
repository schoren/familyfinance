import 'package:flutter/material.dart';

Widget buildButton({VoidCallback? onPressed}) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.login),
    label: const Text('Login with Google'),
     style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
     ),
  );
}
