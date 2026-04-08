import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_iot/home.dart';
// import 'package:smart_iot/login.dart';
import 'package:smart_iot/second_auth.dart';

class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  bool _biometricPassed = false;

  @override
  Widget build(BuildContext context) {
    // REMOVED the StreamBuilder here!
    // AuthGate already confirmed we have a user.

    if (!_biometricPassed) {
      return SecondAuth(
        onAuthenticated:
            () => setState(() {
              _biometricPassed = true;
            }),
      );
    }

    return const Home();
  }
}
