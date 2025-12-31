import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'script_metadata.dart';

class ScriptRepository {
  static const String _scriptsDirName = 'lua_scripts';
  static const String _manifestFileName = 'manifest.json';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final scriptsDir = Directory('${directory.path}/$_scriptsDirName');
    if (!await scriptsDir.exists()) {
      await scriptsDir.create(recursive: true);
    }
    return scriptsDir.path;
  }

  Future<File> get _manifestFile async {
    final path = await _localPath;
    return File('$path/$_manifestFileName');
  }

  Future<List<ScriptMetadata>> listScripts() async {
    try {
      final file = await _manifestFile;
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList.map((e) => ScriptMetadata.fromJson(e)).toList();
    } catch (e) {
      print('Error reading manifest: $e');
      return [];
    }
  }

  Future<void> saveScript(ScriptMetadata metadata, String content) async {
    final path = await _localPath;
    final file = File('$path/${metadata.localPath}');
    await file.writeAsString(content);

    // Update manifest
    final scripts = await listScripts();
    final index = scripts.indexWhere((s) => s.id == metadata.id);
    if (index != -1) {
      scripts[index] = metadata;
    } else {
      scripts.add(metadata);
    }
    await _saveManifest(scripts);
  }

  Future<String?> loadScript(ScriptMetadata metadata) async {
    final path = await _localPath;
    final file = File('$path/${metadata.localPath}');
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  Future<void> _saveManifest(List<ScriptMetadata> scripts) async {
    final file = await _manifestFile;
    final jsonList = scripts.map((e) => e.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
  }

  Future<void> deleteScript(String id) async {
    final scripts = await listScripts();
    final script = scripts.firstWhere(
      (s) => s.id == id,
      orElse: () => throw Exception('Script not found'),
    );

    final path = await _localPath;
    final file = File('$path/${script.localPath}');
    if (await file.exists()) {
      await file.delete();
    }

    scripts.removeWhere((s) => s.id == id);
    await _saveManifest(scripts);
  }
}
