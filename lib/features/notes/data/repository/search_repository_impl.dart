import 'dart:io';
import 'package:hive/hive.dart';
import 'package:mechanix_notes/core/utils/app_logger.dart';
import 'package:mechanix_notes/core/utils/constants.dart';
import 'package:mechanix_notes/features/notes/data/models/note_metadata.dart';
import 'package:mechanix_notes/features/notes/data/models/note_model.dart';
import 'package:mechanix_notes/features/notes/data/repository/search_repository.dart';
import 'package:mechanix_notes/core/exceptions/app_exceptions.dart';

class SearchRepositoryImpl extends SearchRepository {
  Box<NoteModel> get box => Hive.box<NoteModel>(Constants.tableName);

  Future<void> ensureHiveConnected() async {
    try {
      if (!Hive.isBoxOpen(Constants.tableName)) {
        await initializeHive();
        await Hive.openBox<NoteModel>(Constants.tableName);
      }
    } catch (e) {
      AppLogger.e('Failed to open Hive box: $e');
      if (e is FileSystemException && e.message.contains('lock failed')) {
        throw AppAlreadyRunningException();
      }
      rethrow;
    }
  }

  Future<void> initializeHive() async {
    try {
      final home = Platform.environment['HOME'];
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
  Future<List<NoteMetaData>> searchNotes(String query) async {
    try {
      await ensureHiveConnected();

      if (box.isEmpty) {
        return [];
      }

      final queryLower = query.toLowerCase();

      final matchingNotes = box.values
          .where((note) {
            final title = note.title.toLowerCase();
            final preview = note.previewText.toLowerCase();
            return title.contains(queryLower) || preview.contains(queryLower);
          })
          .map((note) {
            return NoteMetaData(
              id: note.id,
              height: note.height,
              title: note.title,
              createdAt: note.createdAt,
              updatedAt: note.updatedAt,
              previewText: note.previewText,
            );
          })
          .toList();

      // Sort desc by updatedAt
      matchingNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      AppLogger.i("Found ${matchingNotes.length} matching notes in repository");

      return matchingNotes;
    } on AppAlreadyRunningException catch (_) {
      rethrow;
    } catch (e) {
      AppLogger.e('Failed to search notes: $e');
      return [];
    }
  }
}
