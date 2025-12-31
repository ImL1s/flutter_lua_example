import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../providers/script_provider.dart';
import 'script_metadata.dart';
import 'script_repository.dart';
import 'signature_verifier.dart';

class ScriptManager extends Notifier<List<ScriptMetadata>> {
  late final ScriptRepository _repository;

  @override
  List<ScriptMetadata> build() {
    _repository = ref.watch(scriptRepositoryProvider);
    return [];
  }

  Future<void> initialize() async {
    state = await _repository.listScripts();
  }

  /// Download a script from a URL and save it if valid
  /// Returns the metadata of the saved script
  Future<ScriptMetadata> downloadAndVerifyScript({
    required String id,
    required String url,
    required String version,
    required String expectedChecksum,
    String? signature,
  }) async {
    try {
      String content;
      if (url.startsWith('mock:')) {
        // Mock download for demo purposes
        await Future.delayed(
          const Duration(seconds: 1),
        ); // Simulate network delay
        if (url.contains('malicious')) {
          content = 'print("This is a malicious script")'; // Checksum will fail
        } else if (url.contains('calc_script')) {
          content =
              '''
print("Running Calc Script v$version")
local a = 10
local b = 20
print("10 + 20 = " .. (a + b))
return a + b
''';
        } else if (url.contains('interop_script')) {
          content =
              '''
print("Running Interop Script v$version")
print("Calling Dart function via bridge...")
-- Assuming 'helloFromDart' is registered
if helloFromDart then
  helloFromDart("Lua says hi!")
else
  print("helloFromDart function not found!")
end
''';
        } else {
          content =
              'print("Hello from Remote Script v$version!\\n Status: Ready")';
        }
      } else {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          throw Exception('Failed to download script: ${response.statusCode}');
        }
        content = response.body;
      }

      // Verify checksum
      if (expectedChecksum != 'MOCK_SKIP' &&
          !SignatureVerifier.verifyChecksum(content, expectedChecksum)) {
        throw Exception('Checksum verification failed');
      }

      // Verify signature if provided
      if (signature != null && signature.isNotEmpty) {
        // TODO: Get public key from secure storage or config
        if (!SignatureVerifier.verifySignature(
          content,
          signature,
          'PUBLIC_KEY_PLACEHOLDER',
        )) {
          throw Exception('Signature verification failed');
        }
      }

      final metadata = ScriptMetadata(
        id: id,
        version: version,
        checksum: expectedChecksum,
        localPath: '$id.lua', // Simple naming for now
        signature: signature,
      );

      await _repository.saveScript(metadata, content);

      // Refresh list
      state = await _repository.listScripts();

      return metadata;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getScriptContent(String id) async {
    final metadata = state.firstWhere(
      (s) => s.id == id,
      orElse: () => throw Exception('Script not found'),
    );
    return await _repository.loadScript(metadata);
  }
}
