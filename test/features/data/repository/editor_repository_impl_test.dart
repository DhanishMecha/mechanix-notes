import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mechanix_notes/features/notes/data/models/note_model.dart';
import 'package:mechanix_notes/features/notes/data/repository/editor_repository_impl.dart';

// ─── Fakes & Mocks ───────────────────────────────────────────────────────────

class MockBox extends Mock implements Box<NoteModel> {}

// Subclass that replaces `box` with our mock and makes `ensureHiveConnected`
// a no-op. This is the correct isolation pattern for a class whose side-effects
// live inside a getter (`box`) rather than in constructor arguments.
class TestEditorRepositoryImpl extends EditorRepositoryImpl {
  final Box<NoteModel> _mockBox;
  TestEditorRepositoryImpl(this._mockBox);

  @override
  Box<NoteModel> get box => _mockBox;

  @override
  Future<void> ensureHiveConnected() async {}
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

final _kCreatedAt = DateTime(2024, 1, 1);
final _kUpdatedAt = DateTime(2024, 1, 2);

NoteModel _makeNote({
  String id = 'note-1',
  String title = 'Test Note',
  String content = '[{"insert":"Hello\\n"}]',
  String plainText = 'Hello',
  String previewText = 'Hello',
  double height = 104.0,
  DateTime? createdAt,
  DateTime? updatedAt,
}) => NoteModel(
  id: id,
  title: title,
  content: content,
  plainText: plainText,
  previewText: previewText,
  height: height,
  createdAt: createdAt ?? _kCreatedAt,
  updatedAt: updatedAt ?? _kUpdatedAt,
);

// ─── Main ─────────────────────────────────────────────────────────────────────

void main() {
  late MockBox mockBox;
  late TestEditorRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(_makeNote());
  });

  setUp(() {
    mockBox = MockBox();
    repository = TestEditorRepositoryImpl(mockBox);
  });

  // ══════════════════════════════════════════════════════════════════════════
  // getNoteById
  // ══════════════════════════════════════════════════════════════════════════

  group('getNoteById', () {
    test('returns the note when it exists in the box', () async {
      final note = _makeNote(id: 'note-1');
      when(() => mockBox.values).thenReturn([note]);

      final result = await repository.getNoteById('note-1');

      expect(result, equals(note));
    });

    test('returns null when no note matches the given id', () async {
      final note = _makeNote(id: 'note-99');
      when(() => mockBox.values).thenReturn([note]);

      final result = await repository.getNoteById('note-1');

      expect(result, isNull);
    });

    test('returns null when the box is empty', () async {
      when(() => mockBox.values).thenReturn([]);

      final result = await repository.getNoteById('note-1');

      expect(result, isNull);
    });

    test('returns the correct note when multiple notes exist', () async {
      final note1 = _makeNote(id: 'note-1', title: 'First');
      final note2 = _makeNote(id: 'note-2', title: 'Second');
      final note3 = _makeNote(id: 'note-3', title: 'Third');
      when(() => mockBox.values).thenReturn([note1, note2, note3]);

      final result = await repository.getNoteById('note-2');

      expect(result, equals(note2));
      expect(result?.title, equals('Second'));
    });

    test(
      'returns first match when duplicate ids exist (firstWhere semantics)',
      () async {
        // Hive enforces unique keys, but this verifies the firstWhere behaviour
        // in getNoteById is correct — it takes the first, not the last.
        final first = _makeNote(id: 'note-1', title: 'First');
        final dupe = _makeNote(id: 'note-1', title: 'Duplicate');
        when(() => mockBox.values).thenReturn([first, dupe]);

        final result = await repository.getNoteById('note-1');

        expect(result?.title, equals('First'));
      },
    );

    test(
      'returns null (does not throw) when box.values throws Exception',
      () async {
        // The impl wraps in try/catch and returns null on any error.
        when(() => mockBox.values).thenThrow(Exception('box error'));

        final result = await repository.getNoteById('note-1');

        expect(result, isNull);
      },
    );

    test(
      'returns null (does not throw) when box.values throws HiveError',
      () async {
        when(() => mockBox.values).thenThrow(HiveError('corrupt box'));

        final result = await repository.getNoteById('note-1');

        expect(result, isNull);
      },
    );

    test('preserves every field of the returned note', () async {
      final createdAt = DateTime(2023, 6, 15);
      final updatedAt = DateTime(2023, 6, 16);
      final note = _makeNote(
        id: 'note-fields',
        title: 'Rich Note',
        content: '[{"insert":"# Heading\\n"}]',
        plainText: 'Heading',
        previewText: 'Heading',
        height: 250.5,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      when(() => mockBox.values).thenReturn([note]);

      final result = await repository.getNoteById('note-fields');

      expect(result?.id, equals('note-fields'));
      expect(result?.title, equals('Rich Note'));
      expect(result?.content, equals('[{"insert":"# Heading\\n"}]'));
      expect(result?.plainText, equals('Heading'));
      expect(result?.previewText, equals('Heading'));
      expect(result?.height, equals(250.5));
      expect(result?.createdAt, equals(createdAt));
      expect(result?.updatedAt, equals(updatedAt));
    });

    test('id comparison is case-sensitive', () async {
      // The impl uses == which is case-sensitive — 'Note-1' ≠ 'note-1'.
      final note = _makeNote(id: 'Note-1');
      when(() => mockBox.values).thenReturn([note]);

      expect(await repository.getNoteById('note-1'), isNull);
      expect(await repository.getNoteById('Note-1'), isNotNull);
    });

    test(
      'does not return a note whose id only differs by whitespace',
      () async {
        // Ensures no accidental trim/normalisation exists in the impl.
        final note = _makeNote(id: 'note-1');
        when(() => mockBox.values).thenReturn([note]);

        expect(await repository.getNoteById(' note-1 '), isNull);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // createNote
  // ══════════════════════════════════════════════════════════════════════════

  group('createNote', () {
    test('calls box.put with note.id as key and the note as value', () async {
      final note = _makeNote(id: 'note-1');
      when(() => mockBox.put(any(), any<NoteModel>())).thenAnswer((_) async {});

      await repository.createNote(note);

      verify(() => mockBox.put('note-1', note)).called(1);
    });

    test('calls box.put exactly once per createNote call', () async {
      final note = _makeNote(id: 'note-1');
      when(() => mockBox.put(any(), any<NoteModel>())).thenAnswer((_) async {});

      await repository.createNote(note);

      verify(() => mockBox.put(any(), any<NoteModel>())).called(1);
    });

    test('uses note.id (not an auto-generated key) as the Hive key', () async {
      final note = _makeNote(id: 'custom-key-abc-123');
      when(() => mockBox.put(any(), any<NoteModel>())).thenAnswer((_) async {});

      await repository.createNote(note);

      verify(
        () => mockBox.put('custom-key-abc-123', any<NoteModel>()),
      ).called(1);
      // Must not use box.add() which generates an auto-increment integer key.
      verifyNever(() => mockBox.add(any<NoteModel>()));
    });

    test('completes normally when box.put succeeds', () async {
      final note = _makeNote();
      when(() => mockBox.put(any(), any<NoteModel>())).thenAnswer((_) async {});

      await expectLater(repository.createNote(note), completes);
    });

    test(
      'swallows and does not rethrow when box.put throws Exception',
      () async {
        final note = _makeNote();
        when(
          () => mockBox.put(any(), any<NoteModel>()),
        ).thenThrow(Exception('write error'));

        await expectLater(repository.createNote(note), completes);
      },
    );

    test(
      'swallows and does not rethrow when box.put throws HiveError',
      () async {
        final note = _makeNote();
        when(
          () => mockBox.put(any(), any<NoteModel>()),
        ).thenThrow(HiveError('disk full'));

        await expectLater(repository.createNote(note), completes);
      },
    );

    test('does not call box.values during createNote', () async {
      final note = _makeNote();
      when(() => mockBox.put(any(), any<NoteModel>())).thenAnswer((_) async {});

      await repository.createNote(note);

      verifyNever(() => mockBox.values);
    });

    test('does not call box.delete during createNote', () async {
      final note = _makeNote();
      when(() => mockBox.put(any(), any<NoteModel>())).thenAnswer((_) async {});

      await repository.createNote(note);

      verifyNever(() => mockBox.delete(any()));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // updateNote
  // ══════════════════════════════════════════════════════════════════════════

  group('updateNote', () {
    test('calls box.put with note.id as key and the note as value', () async {
      final note = _makeNote(id: 'note-1', title: 'Updated Title');
      when(() => mockBox.put(any(), any<NoteModel>())).thenAnswer((_) async {});

      await repository.updateNote(note);

      verify(() => mockBox.put('note-1', note)).called(1);
    });

    test('calls box.put exactly once per updateNote call', () async {
      final note = _makeNote(id: 'note-1');
      when(() => mockBox.put(any(), any<NoteModel>())).thenAnswer((_) async {});

      await repository.updateNote(note);

      verify(() => mockBox.put(any(), any<NoteModel>())).called(1);
    });

    test(
      'uses box.put (upsert) — does not call box.delete before writing',
      () async {
        // Hive's put() overwrites in place; the impl must not delete-then-put.
        final note = _makeNote(id: 'note-1');
        when(
          () => mockBox.put(any(), any<NoteModel>()),
        ).thenAnswer((_) async {});

        await repository.updateNote(note);

        verify(() => mockBox.put('note-1', note)).called(1);
        verifyNever(() => mockBox.delete(any()));
      },
    );

    test('completes normally when box.put succeeds', () async {
      final note = _makeNote();
      when(() => mockBox.put(any(), any<NoteModel>())).thenAnswer((_) async {});

      await expectLater(repository.updateNote(note), completes);
    });

    test(
      'swallows and does not rethrow when box.put throws Exception',
      () async {
        final note = _makeNote();
        when(
          () => mockBox.put(any(), any<NoteModel>()),
        ).thenThrow(Exception('network error'));

        await expectLater(repository.updateNote(note), completes);
      },
    );

    test(
      'swallows and does not rethrow when box.put throws HiveError',
      () async {
        final note = _makeNote();
        when(
          () => mockBox.put(any(), any<NoteModel>()),
        ).thenThrow(HiveError('box closed'));

        await expectLater(repository.updateNote(note), completes);
      },
    );

    test('does not call box.values during updateNote', () async {
      final note = _makeNote();
      when(() => mockBox.put(any(), any<NoteModel>())).thenAnswer((_) async {});

      await repository.updateNote(note);

      verifyNever(() => mockBox.values);
    });

    test(
      'createNote and updateNote both use box.put — same storage path',
      () async {
        // Validates the impl does not diverge between create and update paths.
        final note = _makeNote(id: 'note-1');
        when(
          () => mockBox.put(any(), any<NoteModel>()),
        ).thenAnswer((_) async {});

        await repository.createNote(note);
        await repository.updateNote(note);

        verify(() => mockBox.put('note-1', note)).called(2);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // ensureHiveConnected — test double validation
  //
  // The real ensureHiveConnected() depends on Platform.environment['HOME']
  // and Hive.init() which are platform-specific and inappropriate for unit
  // tests. The TestEditorRepositoryImpl override stubs this out entirely.
  // These tests verify the stub itself behaves correctly so every other group
  // is guaranteed to be isolated from Hive I/O.
  // ══════════════════════════════════════════════════════════════════════════

  group('ensureHiveConnected — test double validation', () {
    test('completes without any I/O in the test double', () async {
      await expectLater(repository.ensureHiveConnected(), completes);
    });

    test(
      'no box interactions occur when only ensureHiveConnected is called',
      () async {
        await repository.ensureHiveConnected();

        verifyNever(() => mockBox.values);
        verifyNever(() => mockBox.put(any(), any<NoteModel>()));
        verifyNever(() => mockBox.delete(any()));
      },
    );

    test(
      'multiple calls to ensureHiveConnected all complete without error',
      () async {
        await repository.ensureHiveConnected();
        await repository.ensureHiveConnected();
        await repository.ensureHiveConnected();

        // No interactions — the override is truly a no-op.
        verifyNever(() => mockBox.values);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Integration — full CRUD lifecycle (mock box wired to an in-memory Map)
  //
  // These tests wire mockBox.put and mockBox.values to a real Map so the
  // create → get → update → get lifecycle can be exercised end-to-end
  // without spinning up a real Hive instance.
  // ══════════════════════════════════════════════════════════════════════════

  group('integration — CRUD lifecycle (mock box)', () {
    late Map<String, NoteModel> storage;

    setUp(() {
      storage = {};

      when(() => mockBox.put(any(), any<NoteModel>())).thenAnswer((inv) async {
        storage[inv.positionalArguments[0] as String] =
            inv.positionalArguments[1] as NoteModel;
      });

      when(() => mockBox.values).thenAnswer((_) => storage.values);
    });

    test('create then get returns the same note', () async {
      final note = _makeNote(id: 'note-42', title: 'Integration');

      await repository.createNote(note);
      final fetched = await repository.getNoteById('note-42');

      expect(fetched, equals(note));
    });

    test('update then get returns the updated note', () async {
      final original = _makeNote(id: 'note-42', title: 'Original');
      final updated = _makeNote(id: 'note-42', title: 'Updated');

      await repository.createNote(original);
      await repository.updateNote(updated);
      final fetched = await repository.getNoteById('note-42');

      expect(fetched?.title, equals('Updated'));
    });

    test('multiple notes can be created and individually retrieved', () async {
      final notes = [
        _makeNote(id: 'n1', title: 'Alpha'),
        _makeNote(id: 'n2', title: 'Beta'),
        _makeNote(id: 'n3', title: 'Gamma'),
      ];

      for (final n in notes) {
        await repository.createNote(n);
      }

      expect((await repository.getNoteById('n1'))?.title, equals('Alpha'));
      expect((await repository.getNoteById('n2'))?.title, equals('Beta'));
      expect((await repository.getNoteById('n3'))?.title, equals('Gamma'));
    });

    test('updating one note does not alter others', () async {
      await repository.createNote(_makeNote(id: 'n1', title: 'Alpha'));
      await repository.createNote(_makeNote(id: 'n2', title: 'Beta'));

      await repository.updateNote(_makeNote(id: 'n1', title: 'Alpha Updated'));

      // n2 must be unaffected.
      expect((await repository.getNoteById('n2'))?.title, equals('Beta'));
    });

    test(
      'full lifecycle: create → update preserves createdAt, advances updatedAt',
      () async {
        final createdAt = DateTime(2020, 1, 1);
        final updatedAt = DateTime(2024, 6, 1);

        await repository.createNote(
          _makeNote(
            id: 'lifecycle-note',
            title: 'Original',
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
        await repository.updateNote(
          _makeNote(
            id: 'lifecycle-note',
            title: 'Updated',
            createdAt:
                createdAt, // must be preserved by caller (bloc responsibility)
            updatedAt: updatedAt, // must advance
          ),
        );

        final fetched = await repository.getNoteById('lifecycle-note');
        expect(fetched?.title, equals('Updated'));
        expect(fetched?.createdAt, equals(createdAt));
        expect(fetched?.updatedAt, equals(updatedAt));
      },
    );

    test(
      'get after failed createNote returns null (put error swallowed)',
      () async {
        // Override put to throw — storage map never receives the note.
        when(
          () => mockBox.put(any(), any<NoteModel>()),
        ).thenThrow(Exception('disk full'));

        await repository.createNote(_makeNote(id: 'fail-note'));
        final fetched = await repository.getNoteById('fail-note');

        expect(fetched, isNull);
      },
    );

    test('get after failed updateNote returns the original note', () async {
      // First create succeeds; then update fails — original must survive.
      await repository.createNote(_makeNote(id: 'n1', title: 'Original'));

      when(
        () => mockBox.put(any(), any<NoteModel>()),
      ).thenThrow(Exception('network error'));

      await repository.updateNote(
        _makeNote(id: 'n1', title: 'Should Not Persist'),
      );
      final fetched = await repository.getNoteById('n1');

      expect(fetched?.title, equals('Original'));
    });

    test(
      'creating the same id twice overwrites the first (Hive upsert)',
      () async {
        await repository.createNote(_makeNote(id: 'dup', title: 'First'));
        await repository.createNote(_makeNote(id: 'dup', title: 'Second'));

        final fetched = await repository.getNoteById('dup');
        expect(fetched?.title, equals('Second'));
      },
    );
  });
}
