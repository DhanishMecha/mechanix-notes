import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mechanix_notes/core/services/hive_service.dart';
import 'package:mechanix_notes/core/utils/app_logger.dart';
import 'package:mechanix_notes/core/utils/constants.dart';
import 'package:mechanix_notes/features/notes/data/models/note_metadata.dart';
import 'package:mechanix_notes/features/notes/data/models/note_model.dart';
import 'package:mechanix_notes/features/notes/data/repository/note_repository.dart';
import 'package:mechanix_notes/core/exceptions/hive_exception.dart';

class NoteRepositoryImpl extends NoteRepository {
  Box<NoteModel> get box => Hive.box<NoteModel>(Constants.tableName);

  /// Overridable hook — test doubles stub this out to skip real Hive I/O.
  Future<void> ensureHiveConnected() => HiveService.ensureHiveConnected();

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
    } on HiveLockedException catch (_) {
      rethrow;
    } catch (e) {
      AppLogger.e('Failed to fetch notes: $e');
      return [];
    }
  }

  @override
  Future<NoteMetaData?> getNoteMetaData(String id) async {
    try {
      await ensureHiveConnected();
      final note = box.get(id);
      if (note != null) {
        return NoteMetaData(
          id: note.id,
          height: note.height,
          title: note.title,
          createdAt: note.createdAt,
          updatedAt: note.updatedAt,
          previewText: note.previewText,
        );
      }
      return null;
    } catch (e) {
      AppLogger.e('Failed to fetch note by id: $e');
      return null;
    }
  }

  List<NoteMetaData> sortNotes(List<NoteMetaData> notes) {
    // Sort in descending by updatedAt
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  @override
  Future<void> deleteNotes(List<String> ids) async {
    try {
      await ensureHiveConnected();
      await box.deleteAll(ids);
      AppLogger.i('NoteRepository: deleteNotes(${ids.length}) ✓');
    } catch (e) {
      AppLogger.e('NoteRepository: deleteNotes failed: $e');
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
        'NoteRepository: getNoteById($id) → ${note == null ? 'not found' : 'found'}',
      );
      return note;
    } catch (e) {
      AppLogger.e('NoteRepository: getNoteById failed: $e');
      return null;
    }
  }

  @override
  Future<void> upsertNote(NoteModel note) async {
    try {
      await ensureHiveConnected();
      await box.put(note.id, note);
      AppLogger.i(
        'NoteRepository: upsertNote(${note.id}) ${note.updatedAt} ${note.title} ✓',
      );
    } catch (e) {
      AppLogger.e('NoteRepository: upsertNote failed: $e');
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
    } on HiveLockedException catch (_) {
      rethrow;
    } catch (e) {
      AppLogger.e('Failed to search notes: $e');
      return [];
    }
  }
}
