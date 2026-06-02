import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mechanix_notes/features/notes/data/models/note_metadata.dart';
import 'package:mechanix_notes/features/notes/data/models/note_model.dart';
import 'package:mechanix_notes/features/notes/data/repository/note_repository_impl.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockHiveBox extends Mock implements Box<NoteModel> {}

class MockNoteModel extends Mock implements NoteModel {}

// ---------------------------------------------------------------------------
// Testable subclass – lets us inject a fake Box without touching Hive globals
// ---------------------------------------------------------------------------

class TestableNoteRepositoryImpl extends NoteRepositoryImpl {
  final Box<NoteModel> fakeBox;
  bool ensureHiveCalled = false;

  TestableNoteRepositoryImpl(this.fakeBox);

  /// Override the getter so the implementation uses our fake box.
  @override
  Box<NoteModel> get box => fakeBox;

  /// Skip real Hive initialisation in tests.
  @override
  Future<void> ensureHiveConnected() async {
    ensureHiveCalled = true;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

NoteModel _makeNote({
  required String id,
  required String title,
  String previewText = '',
  double height = 200,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.now();
  final note = MockNoteModel();
  when(() => note.id).thenReturn(id);
  when(() => note.title).thenReturn(title);
  when(() => note.previewText).thenReturn(previewText);
  when(() => note.height).thenReturn(height);
  when(() => note.createdAt).thenReturn(createdAt ?? now);
  when(() => note.updatedAt).thenReturn(updatedAt ?? now);
  return note;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockHiveBox mockBox;
  late TestableNoteRepositoryImpl repository;

  setUp(() {
    mockBox = MockHiveBox();
    repository = TestableNoteRepositoryImpl(mockBox);
  });

  // -------------------------------------------------------------------------
  // getAllNotes
  // -------------------------------------------------------------------------

  group('getAllNotes', () {
    test('returns empty list when box is empty', () async {
      when(() => mockBox.isEmpty).thenReturn(true);

      final result = await repository.getAllNotes();

      expect(result, isEmpty);
      expect(repository.ensureHiveCalled, isTrue);
    });

    test('returns NoteMetaData list when box has notes', () async {
      final now = DateTime.now();
      final note1 = _makeNote(
        id: '1',
        title: 'Note 1',
        previewText: 'Preview 1',
        height: 150,
        updatedAt: now.subtract(const Duration(hours: 1)),
      );
      final note2 = _makeNote(
        id: '2',
        title: 'Note 2',
        previewText: 'Preview 2',
        height: 200,
        updatedAt: now,
      );

      when(() => mockBox.isEmpty).thenReturn(false);
      when(() => mockBox.values).thenReturn([note1, note2]);

      final result = await repository.getAllNotes();

      expect(result, hasLength(2));
      expect(result.map((n) => n.id), containsAll(['1', '2']));
    });

    test('maps NoteModel fields to NoteMetaData correctly', () async {
      final createdAt = DateTime(2024, 1, 1);
      final updatedAt = DateTime(2024, 6, 1);

      final note = _makeNote(
        id: 'abc',
        title: 'My Note',
        previewText: 'Some preview',
        height: 300,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      when(() => mockBox.isEmpty).thenReturn(false);
      when(() => mockBox.values).thenReturn([note]);

      final result = await repository.getAllNotes();

      expect(result, hasLength(1));
      final meta = result.first;
      expect(meta.id, equals('abc'));
      expect(meta.title, equals('My Note'));
      expect(meta.previewText, equals('Some preview'));
      expect(meta.height, equals(300));
      expect(meta.createdAt, equals(createdAt));
      expect(meta.updatedAt, equals(updatedAt));
    });

    test('sorts notes by updatedAt in descending order', () async {
      final oldest = DateTime(2023, 1, 1);
      final middle = DateTime(2023, 6, 1);
      final newest = DateTime(2024, 1, 1);

      final noteA = _makeNote(id: 'A', title: 'Old Note', updatedAt: oldest);
      final noteB = _makeNote(id: 'B', title: 'Mid Note', updatedAt: middle);
      final noteC = _makeNote(id: 'C', title: 'New Note', updatedAt: newest);

      // Deliberately pass in unsorted order
      when(() => mockBox.isEmpty).thenReturn(false);
      when(() => mockBox.values).thenReturn([noteA, noteC, noteB]);

      final result = await repository.getAllNotes();

      expect(result[0].id, equals('C')); // newest first
      expect(result[1].id, equals('B'));
      expect(result[2].id, equals('A')); // oldest last
    });

    test('returns notes sorted even when timestamps are equal', () async {
      final sameTime = DateTime(2024, 3, 15, 10, 0, 0);

      final note1 = _makeNote(id: '1', title: 'Note 1', updatedAt: sameTime);
      final note2 = _makeNote(id: '2', title: 'Note 2', updatedAt: sameTime);

      when(() => mockBox.isEmpty).thenReturn(false);
      when(() => mockBox.values).thenReturn([note1, note2]);

      final result = await repository.getAllNotes();

      // Both present, order is stable (no crash)
      expect(result, hasLength(2));
    });

    test('returns empty list and does not throw on exception', () async {
      // Simulate box access throwing
      when(() => mockBox.isEmpty).thenThrow(Exception('Hive error'));

      final result = await repository.getAllNotes();

      expect(result, isEmpty);
    });

    test('calls ensureHiveConnected before accessing box', () async {
      when(() => mockBox.isEmpty).thenReturn(true);

      await repository.getAllNotes();

      expect(repository.ensureHiveCalled, isTrue);
    });

    test('returns single note correctly', () async {
      final note = _makeNote(id: 'solo', title: 'Solo Note');

      when(() => mockBox.isEmpty).thenReturn(false);
      when(() => mockBox.values).thenReturn([note]);

      final result = await repository.getAllNotes();

      expect(result, hasLength(1));
      expect(result.first.id, equals('solo'));
    });

    test('handles large number of notes without error', () async {
      final notes = List.generate(500, (i) {
        return _makeNote(
          id: 'note_$i',
          title: 'Note $i',
          updatedAt: DateTime.now().subtract(Duration(minutes: i)),
        );
      });

      when(() => mockBox.isEmpty).thenReturn(false);
      when(() => mockBox.values).thenReturn(notes);

      final result = await repository.getAllNotes();

      expect(result, hasLength(500));
      // Verify descending sort: first item has smallest subtracted duration (most recent)
      for (int i = 0; i < result.length - 1; i++) {
        expect(
          result[i].updatedAt.isAfter(result[i + 1].updatedAt) ||
              result[i].updatedAt.isAtSameMomentAs(result[i + 1].updatedAt),
          isTrue,
          reason: 'Notes should be sorted newest-first',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // _sortNotes (tested indirectly via getAllNotes + directly via reflection)
  // -------------------------------------------------------------------------

  group('_sortNotes (internal sort logic)', () {
    test('sorts descending by updatedAt', () async {
      final t1 = DateTime(2024, 1, 1);
      final t2 = DateTime(2024, 6, 1);
      final t3 = DateTime(2025, 1, 1);

      final notes = [
        NoteMetaData(
          id: '1',
          title: 'A',
          height: 100,
          createdAt: t1,
          updatedAt: t1,
          previewText: '',
        ),
        NoteMetaData(
          id: '2',
          title: 'B',
          height: 100,
          createdAt: t2,
          updatedAt: t3,
          previewText: '',
        ),
        NoteMetaData(
          id: '3',
          title: 'C',
          height: 100,
          createdAt: t2,
          updatedAt: t2,
          previewText: '',
        ),
      ];

      // Access private method via a thin public wrapper for testing
      final sorted = repository.sortNotes(notes);

      expect(sorted[0].id, equals('2')); // t3 – newest
      expect(sorted[1].id, equals('3')); // t2
      expect(sorted[2].id, equals('1')); // t1 – oldest
    });
  });
}
