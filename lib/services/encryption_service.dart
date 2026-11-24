import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncryptionService {
  static String hashPin(String pin, {String salt = 'FamilyVaultSalt2026'}) {
    final bytes = utf8.encode('$salt:$pin');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyPin(String enteredPin, String storedHash, {String salt = 'FamilyVaultSalt2026'}) {
    final calculated = hashPin(enteredPin, salt: salt);
    return calculated == storedHash;
  }

  // Derive stream cipher key from pin
  static List<int> _deriveKey(String pin) {
    final keyBytes = utf8.encode('FamilyVaultKey:$pin');
    return sha256.convert(keyBytes).bytes;
  }

  // Encrypt string with derived PIN key
  static String encryptPayload(String plainText, String pin) {
    if (plainText.isEmpty) return '';
    final plainBytes = utf8.encode(plainText);
    final key = _deriveKey(pin);
    final cipherBytes = List<int>.filled(plainBytes.length, 0);

    for (int i = 0; i < plainBytes.length; i++) {
      cipherBytes[i] = plainBytes[i] ^ key[i % key.length];
    }
    return base64.encode(cipherBytes);
  }

  // Decrypt payload with derived PIN key
  static String decryptPayload(String cipherBase64, String pin) {
    if (cipherBase64.isEmpty) return '';
    try {
      final cipherBytes = base64.decode(cipherBase64);
      final key = _deriveKey(pin);
      final plainBytes = List<int>.filled(cipherBytes.length, 0);

      for (int i = 0; i < cipherBytes.length; i++) {
        plainBytes[i] = cipherBytes[i] ^ key[i % key.length];
      }
      return utf8.decode(plainBytes);
    } catch (e) {
      return '';
    }
  }
}
