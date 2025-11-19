import 'package:encrypt/encrypt.dart' as encrypt;

class AesEncrypt {
  static final key = encrypt.Key.fromUtf8(
    '1234567890123456',
  ); // 16-byte key exactly

  static Future<void> initialize() async {
    // Placeholder for any initialization logic if needed in future.
  }

  static Future<String> encryptValue(String value) async {
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.ecb, padding: null),
    );

    // Ensure value is 16 bytes long exactly (manual padding)
    String padded = value.padRight(16, ' ');

    final encrypted = encrypter.encrypt(padded);
    return encrypted.base64;
  }
}
