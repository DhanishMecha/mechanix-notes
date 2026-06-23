import 'dart:io';
import 'package:mechanix_notes/core/utils/app_logger.dart';
import 'package:mechanix_notes/core/utils/constants.dart';
import 'package:mechanix_notes/features/notes/data/models/note_metadata.dart';
import 'package:mechanix_notes/features/notes/data/models/note_model.dart';
import 'package:mechanix_notes/features/notes/data/repository/note_repository.dart';
import 'package:mechanix_notes/objectbox.g.dart';

class NoteRepositoryImpl extends NoteRepository {
  Store? _store;
  Box<NoteModel>? _box;

  Box<NoteModel> get box {
    if (_box == null) {
      throw StateError("Box is not initialized. Call ensureStoreConnected() first.");
    }
    return _box!;
  }

  Future<void> ensureStoreConnected() async {
    if (_store != null && !_store!.isClosed()) return;

    try {
      await _initializeStore();
    } catch (e) {
      AppLogger.e('Failed to open ObjectBox store: $e');
      if (e is FileSystemException && e.message.contains('lock failed')) {
        throw ObjectBoxException("Failed to open ObjectBox store: $e");
      }
      rethrow;
    }
  }

  Future<void> _initializeStore() async {
    try {
      final home = Platform.environment['HOME'];
      final appDir = Directory('$home${Constants.notesDbPath}');
      final exists = await appDir.exists();

      if (!exists) {
        await appDir.create(recursive: true);
      }

      _store = await openStore(directory: appDir.path);
      _box = _store!.box<NoteModel>();

      AppLogger.i('[NoteRepository] ObjectBox store opened at ${appDir.path}');
    } catch (e) {
      AppLogger.e('Failed to initialize ObjectBox store: $e');
      rethrow;
    }
  }

  @override
  Future<List<NoteMetaData>> getNotes({int? skip, int? take}) async {
    try {
      await ensureStoreConnected();
      final queryBuilder = box.query()
        ..order(NoteModel_.updatedAt, flags: Order.descending);
      final query = queryBuilder.build();

      if (skip != null) {
        query.offset = skip;
      }
      if (take != null) {
        query.limit = take;
      }

      final notes = query.find();
      query.close();

      if (notes.isEmpty) {
        AppLogger.i("No notes found");
        return [];
      }

      final metaDataList = notes.map((note) {
        return NoteMetaData(
          id: note.id,
          height: note.height,
          title: note.title,
          createdAt: note.createdAt,
          updatedAt: note.updatedAt,
          previewText: note.previewText,
        );
      }).toList();

      AppLogger.i("Fetched notes page (skip: $skip, take: $take) → page size: ${metaDataList.length}");
      return metaDataList;
    } catch (e) {
      AppLogger.e('Failed to fetch notes: $e');
      return [];
    }
  }

  @override
  Future<NoteMetaData?> getNoteMetaData(String id) async {
    try {
      await ensureStoreConnected();
      final query = box.query(NoteModel_.id.equals(id)).build();
      final note = query.findFirst();
      query.close();
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
      AppLogger.e('Failed to fetch note metadata by id: $e');
      return null;
    }
  }

  @override
  Future<NoteModel?> getNoteById(String id) async {
    try {
      await ensureStoreConnected();
      final query = box.query(NoteModel_.id.equals(id)).build();
      final note = query.findFirst();
      query.close();
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
  Future<void> deleteNotes(List<String> ids) async {
    try {
      await ensureStoreConnected();
      final query = box.query(NoteModel_.id.oneOf(ids)).build();
      final notesToDelete = query.find();
      query.close();
      if (notesToDelete.isNotEmpty) {
        box.removeMany(notesToDelete.map((n) => n.obxId).toList());
      }
      AppLogger.i('NoteRepository: deleteNotes(${ids.length})');
    } catch (e) {
      AppLogger.e('NoteRepository: deleteNotes failed: $e');
    }
  }

  @override
  Future<void> upsertNote(NoteModel note) async {
    try {
      await ensureStoreConnected();
      final query = box.query(NoteModel_.id.equals(note.id)).build();
      final existing = query.findFirst();
      query.close();
      if (existing != null) {
        note.obxId = existing.obxId;
      }
      box.put(note);
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
      await ensureStoreConnected();
      final q = box.query(
        NoteModel_.title.contains(query, caseSensitive: false)
        .or(NoteModel_.previewText.contains(query, caseSensitive: false))
      ).build();
      final results = q.find();
      q.close();

      final matchingNotes = results.map((note) {
        return NoteMetaData(
          id: note.id,
          height: note.height,
          title: note.title,
          createdAt: note.createdAt,
          updatedAt: note.updatedAt,
          previewText: note.previewText,
        );
      }).toList();

      // Sort desc by updatedAt
      matchingNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      AppLogger.i("Found ${matchingNotes.length} matching notes in repository");
      return matchingNotes;
    } catch (e) {
      AppLogger.e('Failed to search notes: $e');
      return [];
    }
  }
}
