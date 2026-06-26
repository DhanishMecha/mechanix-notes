import 'dart:io';
import 'package:flutter_tantivy/flutter_tantivy.dart';
import 'package:mechanix_notes/core/utils/app_logger.dart';
import 'package:mechanix_notes/core/utils/constants.dart';

class TantivyService {
  bool _tantivyInitialized = false;

  Future<void> initialize() async {
    if (_tantivyInitialized) return;
    try {
      await RustLib.init();
      final home = Platform.environment['HOME'];
      final tantivyDir = Directory('$home${Constants.notesTantivyDbPath}');
      if (!await tantivyDir.exists()) {
        await tantivyDir.create(recursive: true);
      }
      initTantivy(dirPath: tantivyDir.path);
      _tantivyInitialized = true;
      AppLogger.i(
        '[TantivyService] Initialized successfully at ${tantivyDir.path}',
      );
    } catch (e) {
      AppLogger.e('[TantivyService] Initialization failed: $e');
      rethrow;
    }
  }

  /// Limits content to the maximum characters and words allowed for indexing.
  static String truncateContent(String plainText) {
    String truncatedPlainText = plainText;
    if (truncatedPlainText.length > Constants.tantivyIndexContentMaxLength) {
      truncatedPlainText = truncatedPlainText.substring(
        0,
        Constants.tantivyIndexContentMaxLength,
      );
    }
    final wordMatches = RegExp(r'\S+').allMatches(truncatedPlainText);
    if (wordMatches.length > Constants.tantivyIndexContentMaxWords) {
      final endOfMaxWords = wordMatches
          .elementAt(Constants.tantivyIndexContentMaxWords - 1)
          .end;
      truncatedPlainText = truncatedPlainText.substring(0, endOfMaxWords);
    }
    return truncatedPlainText;
  }

  Future<void> addNote(String id, String title, String plainText) async {
    try {
      if (!_tantivyInitialized) {
        await initialize();
      }
      final truncatedPlainText = truncateContent(plainText);
      await updateDocument(
        doc: Document(id: id, text: '$title\n$truncatedPlainText'),
      );
    } catch (e) {
      AppLogger.e('[TantivyService] Failed to add note ($id): $e');
    }
  }

  Future<void> deleteNotesBatch(List<String> ids) async {
    try {
      if (!_tantivyInitialized) {
        await initialize();
      }
      await deleteDocumentsBatch(ids: ids);
    } catch (e) {
      AppLogger.e('[TantivyService] Failed to delete notes batch: $e');
    }
  }

  /// Performs a full-text search against the Tantivy index, returning matching document IDs in order of relevance.
  Future<List<String>> search(String query, {int limit = 100}) async {
    try {
      if (!_tantivyInitialized) {
        await initialize();
      }
      final cleanQuery = query.trim();
      if (cleanQuery.isEmpty) return [];

      final results = await searchDocuments(
        query: cleanQuery,
        topK: BigInt.from(limit),
      );

      AppLogger.i('[TantivyService] "$cleanQuery" → ${results.length} results');

      return results.map((r) => r.doc.id).toSet().toList();
    } catch (e) {
      AppLogger.e('[TantivyService] Search failed for "$query": $e');
      return [];
    }
  }
}
