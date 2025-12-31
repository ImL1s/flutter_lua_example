import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../script_manager/script_manager.dart';
import '../script_manager/script_metadata.dart';
import '../script_manager/script_repository.dart';

final scriptRepositoryProvider = Provider<ScriptRepository>((ref) {
  return ScriptRepository();
});

final scriptManagerProvider =
    NotifierProvider<ScriptManager, List<ScriptMetadata>>(ScriptManager.new);
