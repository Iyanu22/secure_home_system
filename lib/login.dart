import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SMART IOT')),
      body: SignInScreen(
        providers: [
          EmailAuthProvider(),
          // PhoneAuthProvider(),
        ],
      ),
    );
  }
}
