import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:smart_iot/motion_service.dart';
import 'package:smart_iot/notification_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'aes_encrypt.dart';
import 'inactivity_service.dart';

final storage = const FlutterSecureStorage();

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final InactivityService _inactivityService = InactivityService();

  bool on = true;
  bool doorOpen = true;
  bool motionDetected = false;
  String motionStatus = "Unknown";
  String lastKnownMotion = "Unknown";

  final DatabaseReference motionRef = FirebaseDatabase.instance.ref(
    "sensor/motion",
  );
  final DatabaseReference controls = FirebaseDatabase.instance.ref("controls");

  @override
  void initState() {
    super.initState();

    // ✅ Start inactivity timer as soon as Home is loaded
    _inactivityService.initialize(timeout: const Duration(seconds: 10));

    // ✅ Start listening for motion updates
    _listenForMotion();
  }

  @override
  void dispose() {
    _inactivityService.dispose();
    super.dispose();
  }

  /// 🔹 Listen for motion updates from Firebase Realtime Database
  void _listenForMotion() {
    motionRef.onValue.listen((event) {
      final encryptedMotion = event.snapshot.value.toString();
      final result = MotionService.decryptBase64Motion(encryptedMotion);

      setState(() {
        motionStatus = result;
        motionDetected = (result == "true");
      });

      if (result == "true" && lastKnownMotion != "true") {
        NotificationService.showNotification(
          "Motion Detected",
          "Motion detected in your home!",
        );
      }
      lastKnownMotion = result;
    });
  }

  /// 🔹 Reset inactivity timer on user activity
  void _onUserInteraction() {
    _inactivityService.userActivityDetected();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _onUserInteraction(),
      onPointerMove: (_) => _onUserInteraction(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SMART IOT'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
        backgroundColor: Colors.grey[300],
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 🔹 Light Control
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  on
                      ? Icon(
                        Icons.lightbulb,
                        size: 80,
                        color: Colors.amber.shade700,
                      )
                      : const Icon(Icons.lightbulb_outline, size: 80),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: on ? Colors.lightGreen : Colors.white10,
                    ),
                    onPressed: () async {
                      setState(() {
                        on = !on;
                      });
                      String encrypted = await AesEncrypt.encryptValue(
                        (!on).toString(),
                      );
                      await controls.child("light").set(encrypted);
                      await storage.write(key: 'led_state', value: encrypted);
                    },
                    child: Text(on ? 'Led On' : 'Led Off'),
                  ),
                ],
              ),

              // 🔹 Door Control
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  doorOpen
                      ? Icon(
                        Icons.door_back_door,
                        size: 80,
                        color: Colors.brown[700],
                      )
                      : const Icon(Icons.door_back_door_outlined, size: 80),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          doorOpen ? Colors.lightGreen : Colors.white10,
                    ),
                    onPressed: () async {
                      setState(() {
                        doorOpen = !doorOpen;
                      });
                      String encrypted = await AesEncrypt.encryptValue(
                        (!doorOpen).toString(),
                      );
                      await controls.child("door").set(encrypted);
                      await storage.write(key: 'door_state', value: encrypted);
                    },
                    child: Text(doorOpen ? 'Door Open' : 'Door Closed'),
                  ),
                ],
              ),

              // 🔹 Motion Indicator
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  motionDetected
                      ? Icon(Icons.dangerous, size: 80, color: Colors.red[700])
                      : const Icon(Icons.dangerous_outlined, size: 80),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          motionDetected ? Colors.lightGreen : Colors.white10,
                    ),
                    onPressed: () {},
                    child: Text(
                      motionDetected ? 'Motion Detected' : 'No Motion',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
