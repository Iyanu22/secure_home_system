import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_iot/login.dart';
import 'firebase_options.dart';
import 'package:smart_iot/auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_iot/aes_encrypt.dart';
import 'package:smart_iot/notification_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first as it's critical for AuthGate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Run the app IMMEDIATELY
  runApp(const MyApp());

  // Load these in the background so they don't block the splash screen
  Future.wait([
    AesEncrypt.initialize(),       // ✅ saves 'aes_secret_key' to secure storage
    NotificationService.initialize(), // ✅ sets up notifications
  ]);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMART IOT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 148, 129, 182),
        ),
      ),
      navigatorKey: navigatorKey,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return FutureBuilder(
            future: Future.delayed(const Duration(minutes: 10)),
            builder: (context, timeoutSnapshot) {
              if (timeoutSnapshot.connectionState == ConnectionState.done) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, size: 50, color: Colors.red),
                        const Text("Connection Timeout"),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/'),
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        if (snapshot.hasData) {
          return const Auth();
        } else {
          return const Login();
        }
      },
    );
  }
}