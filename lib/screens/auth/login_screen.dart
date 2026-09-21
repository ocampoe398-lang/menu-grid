import 'package:flutter/material.dart';

// TODO: implementar pantalla de login — Feature [1] del MVP
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text(
          'MenuQR 🍽️\nPróximamente...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
