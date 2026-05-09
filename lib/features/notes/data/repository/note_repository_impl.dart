import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mechanix_notes/core/utils/app_logger.dart';
import 'package:mechanix_notes/core/utils/constants.dart';
import 'package:mechanix_notes/features/notes/data/models/note_metadata.dart';
import 'package:mechanix_notes/features/notes/data/models/note_model.dart';
import 'package:mechanix_notes/features/notes/data/repository/note_repository.dart';

class NoteRepositoryImpl extends NoteRepository {
  Box<NoteModel> get box => Hive.box<NoteModel>(Constants.tableName);

  Future<void> ensureHiveConnected() async {
    try {
      if (!Hive.isBoxOpen(Constants.tableName)) {
        await initializeHive();
        await Hive.openBox<NoteModel>(Constants.tableName);
      }
    } catch (e) {
      AppLogger.e('Failed to open Hive box: $e');
    }
  }

  Future<void> initializeHive() async {
    try {
      final home = Platform.environment['HOME'];
      // path of hive: /home/user/.config/mechanix_notes
      final baseDir = '$home/.config';
      final appDir = Directory('$baseDir/mechanix_notes');
      final exists = await appDir.exists();

      if (!exists) {
        await appDir.create(recursive: true);
      }

      Hive.init(appDir.path);
    } catch (e) {
      AppLogger.e('Failed to initialize Hive: $e');
    }
  }

  @override
  Future<List<NoteMetaData>> getAllNotes() async {
    try {
      await ensureHiveConnected();

      if (box.isEmpty) {
        AppLogger.i("No notes found");
        return [];
      }

      // Extract metadata
      final notes = box.values.map((note) {
        return NoteMetaData(
          id: note.id,
          height: note.height,
          title: note.title,
          createdAt: note.createdAt,
          updatedAt: note.updatedAt,
          previewText: note.previewText,
        );
      }).toList();

      // Compute to sort notes in background isolate
      final sortedNotes = await compute(sortNotes, notes);

      AppLogger.i("Fetched all notes → total: ${sortedNotes.length}");

      return sortedNotes;
    } catch (e) {
      AppLogger.e('Failed to fetch notes: $e');
      return [];
    }
  }

  List<NoteMetaData> sortNotes(List<NoteMetaData> notes) {
    // Sort in descending by updatedAt
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }
}
