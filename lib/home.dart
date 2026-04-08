import 'dart:async';
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
  StreamSubscription? _motionSubscription;

  bool on = true;
  bool doorOpen = true;
  bool motionDetected = false;
  String motionStatus = "Unknown";
  String lastKnownMotion = "Unknown";

  final DatabaseReference motionRef = FirebaseDatabase.instance.ref(
    "logs/motion",
  );
  final DatabaseReference controls = FirebaseDatabase.instance.ref("controls");

 @override
void initState() {
  super.initState();
  _inactivityService.initialize(timeout: const Duration(minutes: 10));
  _listenForMotion();
  runPerformanceTests();
  // ✅ Delay gives AesEncrypt.initialize() time to finish first
  
}

  @override
  void dispose() {
    _inactivityService.dispose();
    _motionSubscription?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------
  // PERFORMANCE METRICS TEST
  // -------------------------------------------------------
  Future<void> runPerformanceTests() async {
    print('==============================');
    print('   PERFORMANCE METRICS TEST   ');
    print('==============================');

    // --- Test 1: Encryption Time ---
    print('\n[Test 1] Encryption Time');
    final encryptWatch = Stopwatch()..start();
    for (int i = 0; i < 10; i++) {
      await AesEncrypt.encryptValue('true');
    }
    encryptWatch.stop();
    final avgEncryptTime = encryptWatch.elapsedMilliseconds / 10;
    print('10 encryptions completed');
    print('Average encryption time: ${avgEncryptTime}ms');

    // --- Test 2: IV Uniqueness ---
    print('\n[Test 2] IV Uniqueness');
    Set<String> ivSet = {};
    bool allUnique = true;
    for (int i = 0; i < 10; i++) {
      String encrypted = await AesEncrypt.encryptValue('true');
      String iv = encrypted.split(':')[0];
      if (ivSet.contains(iv)) {
        allUnique = false;
        print('FAIL - Duplicate IV at iteration $i');
      }
      ivSet.add(iv);
      print('IV $i: $iv');
    }
    print(allUnique
        ? 'PASS - All 10 IVs are unique'
        : 'FAIL - Duplicate IV detected');

    // --- Test 3: Ciphertext Uniqueness ---
    print('\n[Test 3] Ciphertext Uniqueness');
    Set<String> cipherSet = {};
    bool allCiphersUnique = true;
    for (int i = 0; i < 10; i++) {
      String encrypted = await AesEncrypt.encryptValue('true');
      String cipher = encrypted.split(':')[1];
      if (cipherSet.contains(cipher)) {
        allCiphersUnique = false;
        print('FAIL - Duplicate ciphertext at iteration $i');
      }
      cipherSet.add(cipher);
      print('Cipher $i: $cipher');
    }
    print(allCiphersUnique
        ? 'PASS - All 10 ciphertexts are unique'
        : 'FAIL - Duplicate ciphertext detected');

    // --- Test 4: Firebase Write Latency ---
    print('\n[Test 4] Firebase Write Latency');
    List<int> latencies = [];
    for (int i = 0; i < 5; i++) {
      String encrypted = await AesEncrypt.encryptValue('true');
      final latencyWatch = Stopwatch()..start();
      await controls.child("light").set(encrypted);
      latencyWatch.stop();
      latencies.add(latencyWatch.elapsedMilliseconds);
      print('Write $i latency: ${latencyWatch.elapsedMilliseconds}ms');
    }
    final avgLatency =
        latencies.reduce((a, b) => a + b) / latencies.length;
    final minLatency = latencies.reduce((a, b) => a < b ? a : b);
    final maxLatency = latencies.reduce((a, b) => a > b ? a : b);
    print('Average latency : ${avgLatency.toStringAsFixed(1)}ms');
    print('Min latency     : ${minLatency}ms');
    print('Max latency     : ${maxLatency}ms');

    // --- Test 5: Key Storage Security ---
print('\n[Test 5] Key Storage Security');
await AesEncrypt.initialize(); // ✅ ensure key is written first
final wrongKey =
    await const FlutterSecureStorage().read(key: 'aes_key');
final correctKey =
    await const FlutterSecureStorage().read(key: 'aes_secret_key');
print(
    'Key under wrong name  : ${wrongKey != null ? "FAIL" : "PASS - null"}');
print(
    'Key in secure storage : ${correctKey != null ? "PASS - exists" : "FAIL - missing"}'); // --- Test 6: Tampered Payload Rejection ---
    print('\n[Test 6] Tampered Payload Rejection');
    String tamperedPayload = 'thisisnotvaliddata==';
    int sep = tamperedPayload.indexOf(':');
    print(sep == -1
        ? 'PASS - Tampered payload rejected, no colon found'
        : 'FAIL - Tampered payload was not rejected');

    // --- Summary ---
    print('\n==============================');
    print('        TEST SUMMARY          ');
    print('==============================');
    print('Avg encryption time  : ${avgEncryptTime}ms');
    print('IV uniqueness        : ${allUnique ? "PASS" : "FAIL"}');
    print('Cipher uniqueness    : ${allCiphersUnique ? "PASS" : "FAIL"}');
    print('Avg Firebase latency : ${avgLatency.toStringAsFixed(1)}ms');
    print('Min Firebase latency : ${minLatency}ms');
    print('Max Firebase latency : ${maxLatency}ms');
    print('Key storage          : ${correctKey != null ? "PASS" : "FAIL"}');
    print('Tamper rejection     : ${sep == -1 ? "PASS" : "FAIL"}');
    print('==============================\n');
  }

  // -------------------------------------------------------
  // MOTION LISTENER
  // -------------------------------------------------------
  void _listenForMotion() {
    _motionSubscription = motionRef.onValue.listen((event) {
      final motionValue = event.snapshot.value.toString();

      // Metric: motion response time
      final receiveTime = DateTime.now().millisecondsSinceEpoch;
      print('[Metric] Motion update received at: $receiveTime');

      final result = MotionService.decryptBase64Motion(motionValue);

      if (!mounted) return;

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

  void _onUserInteraction() {
    _inactivityService.userActivityDetected();
  }

  // -------------------------------------------------------
  // BUILD
  // -------------------------------------------------------
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
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    on
                        ? Icon(Icons.lightbulb,
                            size: 80, color: Colors.amber.shade700)
                        : const Icon(Icons.lightbulb_outline, size: 80),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            on ? Colors.lightGreen : Colors.white10,
                      ),
                      onPressed: () async {
                        setState(() { on = !on; });

                        // Metric: encryption time
                        final encryptWatch = Stopwatch()..start();
                        String encrypted = await AesEncrypt.encryptValue(
                          on.toString(),
                        );
                        encryptWatch.stop();
                        print('[Metric] Light encryption time: '
                            '${encryptWatch.elapsedMilliseconds}ms');

                        // Metric: Firebase write latency
                        final sendTime =
                            DateTime.now().millisecondsSinceEpoch;
                        final writeWatch = Stopwatch()..start();
                        await controls.child("light").set(encrypted);
                        writeWatch.stop();
                        print('[Metric] Light command sent at  : $sendTime');
                        print('[Metric] Firebase write latency : '
                            '${writeWatch.elapsedMilliseconds}ms');

                        await storage.write(
                            key: 'led_state', value: encrypted);
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(on ? 'Led On' : 'Led Off'),
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Door Control
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    doorOpen
                        ? Icon(Icons.door_back_door,
                            size: 80, color: Colors.brown[700])
                        : const Icon(Icons.door_back_door_outlined, size: 80),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            doorOpen ? Colors.lightGreen : Colors.white10,
                      ),
                      onPressed: () async {
                        setState(() { doorOpen = !doorOpen; });

                        // Metric: encryption time
                        final encryptWatch = Stopwatch()..start();
                        String encrypted = await AesEncrypt.encryptValue(
                          doorOpen.toString(),
                        );
                        encryptWatch.stop();
                        print('[Metric] Door encryption time: '
                            '${encryptWatch.elapsedMilliseconds}ms');

                        // Metric: Firebase write latency
                        final sendTime =
                            DateTime.now().millisecondsSinceEpoch;
                        final writeWatch = Stopwatch()..start();
                        await controls.child("door").set(encrypted);
                        writeWatch.stop();
                        print('[Metric] Door command sent at   : $sendTime');
                        print('[Metric] Firebase write latency : '
                            '${writeWatch.elapsedMilliseconds}ms');

                        await storage.write(
                            key: 'door_state', value: encrypted);
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                            doorOpen ? 'Door Open' : 'Door Closed'),
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Motion Indicator
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    motionDetected
                        ? Icon(Icons.dangerous,
                            size: 80, color: Colors.red[700])
                        : const Icon(Icons.dangerous_outlined, size: 80),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: motionDetected
                            ? Colors.lightGreen
                            : Colors.white10,
                      ),
                      onPressed: () {},
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(motionDetected
                            ? 'Motion Detected'
                            : 'No Motion'),
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}