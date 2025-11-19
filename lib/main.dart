import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_iot/login.dart';
import 'firebase_options.dart';
import 'package:smart_iot/auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_iot/aes_encrypt.dart';
import 'package:smart_iot/motion_service.dart';
import 'package:smart_iot/notification_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AesEncrypt.initialize();
  await FlutterSecureStorage().write(key: 'aes_key', value: '1234567890123456');
  await MotionService.initialize();
  await NotificationService.initialize();
  // final aesKeyService = AESKeyService();
  // await aesKeyService
  //     .initializeAESKey(); // Ensure AES key is initialized before Firebase
  //final storage = FlutterSecureStorage();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return const Auth();
        } else {
          return const Login();
        }
      },
    );
  }
}
