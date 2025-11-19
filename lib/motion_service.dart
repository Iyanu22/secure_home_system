import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class MotionService {
  static final storage = FlutterSecureStorage();
  static late encrypt.Key key;

  static Future<void> initialize() async {
    String? storedKey = await storage.read(key: 'aes_key');
    if (storedKey == null || storedKey.length != 16) {
      throw Exception('AES key missing or invalid length. Set it first.');
    }
    key = encrypt.Key.fromUtf8(storedKey);
  }

  static String decryptBase64Motion(String encryptedBase64) {
    try {
      final encryptedBytes = base64.decode(encryptedBase64);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.ecb, padding: null),
      );
      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(encryptedBytes),
      );
      final result = utf8.decode(decrypted).trim();
      return result;
    } catch (e) {
      return 'Invalid';
    }
  }
}

// class MotionWidget extends StatefulWidget {
//   const MotionWidget({Key? key}) : super(key: key);

//   @override
//   _MotionWidgetState createState() => _MotionWidgetState();
// }

// class _MotionWidgetState extends State<MotionWidget> {
//   final DatabaseReference motionRef = FirebaseDatabase.instance.ref(
//     "sensor/motion",
//   );
//   String motionStatus = "Unknown";

//   @override
//   void initState() {
//     super.initState();
//     MotionService.initialize().then((_) => _listenForMotion());
//   }

//   void _listenForMotion() {
//     motionRef.onValue.listen((event) {
//       final encryptedMotion = event.snapshot.value.toString();
//       final result = MotionService.decryptBase64Motion(encryptedMotion);
//       setState(() {
//         motionStatus = result;
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text(
//         'Motion Detected: $motionStatus',
//         style: const TextStyle(fontSize: 24),
//       ),
//     );
//   }
// }
