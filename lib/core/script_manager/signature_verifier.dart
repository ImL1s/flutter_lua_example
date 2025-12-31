import 'dart:convert';
import 'package:crypto/crypto.dart';

class SignatureVerifier {
  /// Verify the SHA-256 checksum of the content
  static bool verifyChecksum(String content, String expectedChecksum) {
    if (expectedChecksum.isEmpty) return false;

    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString() == expectedChecksum;
  }

  /// Verify RSA signature (Placeholder for future implementation)
  static bool verifySignature(
    String content,
    String signature,
    String publicKey,
  ) {
    // TODO: Implement RSA signature verification
    // This requires additional dependencies like pointycastle or encrypt
    return true;
  }

  static String calculateChecksum(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
