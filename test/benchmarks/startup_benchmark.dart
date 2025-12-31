import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/lua_engine/lua_engine.dart';
import '../../lib/core/lua_engine/lua_engine_dart.dart';

void main() {
  group('Startup & Memory Benchmarks', () {
    test('Startup time', () async {
      final stopwatch = Stopwatch()..start();

      final LuaEngine engine = LuaEngineDart.create();
      await engine.init();

      stopwatch.stop();
      print('Engine Startup Time: ${stopwatch.elapsedMilliseconds} ms');
    });

    test('Memory usage', () async {
      final LuaEngine engine = LuaEngineDart.create();
      await engine.init();

      final initialMemory = ProcessInfo.currentRss;
      print('Initial Memory: ${initialMemory / 1024 / 1024} MB');

      // Create a large table
      await engine.eval('''
        t = {}
        for i = 1, 100000 do
          t[i] = "string_" .. i
        end
      ''');

      final peakMemory = ProcessInfo.currentRss;
      print('Peak Memory (100k items): ${peakMemory / 1024 / 1024} MB');
      print('Delta: ${(peakMemory - initialMemory) / 1024 / 1024} MB');

      // Clear and GC
      await engine.eval('t = nil');
      engine.collectGarbage();
      // Force Dart GC if possible, or wait a bit
      await Future.delayed(const Duration(milliseconds: 100));

      final finalMemory = ProcessInfo.currentRss;
      print('Final Memory (after GC): ${finalMemory / 1024 / 1024} MB');
    });
  });
}
