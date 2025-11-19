import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_iot/home.dart';
import 'package:smart_iot/login.dart';
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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 🔹 Still loading Firebase user state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🔹 User NOT logged in → go to LoginPage
        if (!snapshot.hasData) {
          return const Login();
        }

        // 🔹 User is logged in, but hasn’t passed biometric yet
        if (!_biometricPassed) {
          return SecondAuth(
            onAuthenticated:
                () => setState(() {
                  _biometricPassed = true;
                }),
          );
        }

        // 🔹 User is logged in AND passed biometric → show Home
        return const Home();
      },
    );
  }
}
