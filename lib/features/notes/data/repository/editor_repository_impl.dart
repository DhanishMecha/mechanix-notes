import 'dart:io';

import 'package:mechanix_notes/core/utils/app_logger.dart';
import 'package:mechanix_notes/core/utils/constants.dart';
import 'package:mechanix_notes/features/notes/data/models/note_model.dart';
import 'package:hive/hive.dart';
import 'package:mechanix_notes/features/notes/data/repository/editor_repository.dart';

class EditorRepositoryImpl extends EditorRepository {
  Box<NoteModel> get box => Hive.box<NoteModel>(Constants.tableName);

  Future<void> ensureHiveConnected() async {
    try {
      if (!Hive.isBoxOpen(Constants.tableName)) {
        await _initializeHive();
        await Hive.openBox<NoteModel>(Constants.tableName);
      }
    } catch (e) {
      AppLogger.e('EditorRepository: Failed to open Hive box: $e');
    }
  }

  Future<void> _initializeHive() async {
    try {
      final home = Platform.environment['HOME'];
      final appDir = Directory('$home/.config/mechanix_notes');
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      Hive.init(appDir.path);
    } catch (e) {
      AppLogger.e('EditorRepository: Failed to initialise Hive: $e');
    }
  }

  @override
  Future<NoteModel?> getNoteById(String id) async {
    try {
      await ensureHiveConnected();

      final note = box.values.cast<NoteModel?>().firstWhere(
        (n) => n?.id == id,
        orElse: () => null,
      );

      AppLogger.i(
        'EditorRepository: getNoteById($id) → ${note == null ? 'not found' : 'found'}',
      );
      return note;
    } catch (e) {
      AppLogger.e('EditorRepository: getNoteById failed: $e');
      return null;
    }
  }

  @override
  Future<void> createNote(NoteModel note) async {
    try {
      await ensureHiveConnected();
      await box.put(note.id, note);
      AppLogger.i(
        'EditorRepository: createNote(${note.id}) ${note.updatedAt} ${note.title} ✓',
      );
    } catch (e) {
      AppLogger.e('EditorRepository: createNote failed: $e');
    }
  }

  @override
  Future<void> updateNote(NoteModel note) async {
    try {
      await ensureHiveConnected();
      await box.put(note.id, note);
      AppLogger.i(
        'EditorRepository: updateNote(${note.id}) ${note.updatedAt} ${note.title} ✓',
      );
    } catch (e) {
      AppLogger.e('EditorRepository: updateNote failed: $e');
    }
  }
}
