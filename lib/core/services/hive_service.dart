import 'dart:io';
import 'package:hive/hive.dart';
import 'package:mechanix_notes/core/exceptions/hive_exception.dart';
import 'package:mechanix_notes/core/utils/app_logger.dart';
import 'package:mechanix_notes/core/utils/constants.dart';
import 'package:mechanix_notes/features/notes/data/models/note_model.dart';

class HiveService {
  HiveService._();

  static bool _initialized = false;

  static Future<void> ensureHiveConnected() async {
    if (Hive.isBoxOpen(Constants.tableName)) return;

    try {
      if (!_initialized) {
        await _initialize();
      }

      await Hive.openBox<NoteModel>(Constants.tableName);
    } catch (e) {
      AppLogger.e('Failed to open Hive box: $e');
      if (e is FileSystemException && e.message.contains('lock failed')) {
        throw HiveLockedException();
      }
      rethrow;
    }
  }

  static Future<void> _initialize() async {
    try {
      final home = Platform.environment['HOME'];
      final appDir = Directory('$home${Constants.notesDbPath}');

      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }

      Hive.init(appDir.path);
      _initialized = true;
    } catch (e) {
      AppLogger.e('Failed to initialize Hive: $e');
      rethrow; // propagate so ensureConnected can catch it
    }
  }
}
