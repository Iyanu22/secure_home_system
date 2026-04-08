import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AesEncrypt {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // Uses Android Keystore
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock, // Survives reboot
    ),
  );

  static const _keyStorageKey = 'aes_secret_key';

  // ✅ Call this once in main.dart before runApp()
  static Future<void> initialize() async {
    final existing = await _storage.read(key: _keyStorageKey);
    if (existing == null) {
      // First launch: save your AES key securely
      await _storage.write(
        key: _keyStorageKey,
        value: '1234567890123456', // 🔑 Replace with your real 16-char key
      );
      print('AES key stored securely.');
    } else {
      print('AES key already exists in secure storage.');
    }
  }

  // ✅ Reads the key from secure storage
  static Future<encrypt.Key> _getKey() async {
    final keyString = await _storage.read(key: _keyStorageKey);
    if (keyString == null) {
      throw Exception('AES key not found. Did you call initialize()?');
    }
    return encrypt.Key.fromUtf8(keyString);
  }

  // ✅ Encrypts a value and returns "ivBase64:encryptedBase64"
  static Future<String> encryptValue(String value) async {
    final key = await _getKey();
    final iv = encrypt.IV.fromSecureRandom(16); // Fresh random IV every time

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );

    final encrypted = encrypter.encrypt(value, iv: iv);

    // Bundle IV and encrypted data together with a colon separator
    return '${iv.base64}:${encrypted.base64}';
  }

  // ✅ Optional: update the key if you ever need to rotate it
  static Future<void> updateKey(String newKey) async {
    if (newKey.length != 16) {
      throw Exception('Key must be exactly 16 characters.');
    }
    await _storage.write(key: _keyStorageKey, value: newKey);
    print('AES key updated.');
  }

  // ✅ Optional: wipe the key (e.g. on logout)
  static Future<void> deleteKey() async {
    await _storage.delete(key: _keyStorageKey);
    print('AES key deleted from secure storage.');
  }
}