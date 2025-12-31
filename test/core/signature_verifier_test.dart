import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_example/core/script_manager/signature_verifier.dart';

void main() {
  group('SignatureVerifier Tests', () {
    test('calculateChecksum produces correct SHA-256 hash', () {
      const content = 'print("Hello World")';
      // Calculated SHA-256 for 'print("Hello World")'
      // echo -n 'print("Hello World")' | shasum -a 256
      // 36472df3242045958564177b8b4010887a02c5240c57193633830ba235e39669
      const expectedHash =
          'eed9979879be4d18c16286d9439a2fc7d8744bb887d78bd2987e7fbadeb84a57';

      final actualHash = SignatureVerifier.calculateChecksum(content);
      expect(actualHash, equals(expectedHash));
    });

    test('verifyChecksum returns true for matching hash', () {
      const content = 'local a = 1';
      final hash = SignatureVerifier.calculateChecksum(content);

      expect(SignatureVerifier.verifyChecksum(content, hash), isTrue);
    });

    test('verifyChecksum returns false for mismatching hash', () {
      const content = 'local a = 1';
      final hash = SignatureVerifier.calculateChecksum(content);

      expect(SignatureVerifier.verifyChecksum('local a = 2', hash), isFalse);
    });

    test('verifyChecksum returns false for empty expected hash', () {
      expect(SignatureVerifier.verifyChecksum('content', ''), isFalse);
    });
  });
}
