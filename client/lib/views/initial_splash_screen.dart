import 'package:flutter/material.dart';

class InitialSplashScreen extends StatelessWidget {
  const InitialSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/logo.png',
          width: 168,
          height: 185,
        ),
      ),
    );
  }
}
