import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class SecondAuth extends StatelessWidget {
  final VoidCallback onAuthenticated;
  const SecondAuth({super.key, required this.onAuthenticated});

  @override
  Widget build(BuildContext context) {
    final auth = LocalAuthentication();

    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final authenticated = await auth.authenticate(
              localizedReason: 'Please authenticate to continue',
              options: const AuthenticationOptions(
                biometricOnly: false,
                stickyAuth: true,
              ),
            );
            if (authenticated) {
              onAuthenticated(); // ✅ tells AuthGate that biometrics passed
            }
          },
          child: const Text('Authenticate'),
        ),
      ),
    );
  }
}
