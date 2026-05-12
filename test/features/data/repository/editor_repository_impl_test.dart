import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mechanix_notes/core/utils/constants.dart';
import 'package:mechanix_notes/features/notes/data/models/note_model.dart';
import 'package:mechanix_notes/features/notes/data/repository/editor_repository_impl.dart';

// ---------------------------------------------------------------------------
// Fakes & Mocks
// ---------------------------------------------------------------------------

class MockBox extends Mock implements Box<NoteModel> {}

class TestEditorRepositoryImpl extends EditorRepositoryImpl {
  final Box<NoteModel> _mockBox;

  TestEditorRepositoryImpl(this._mockBox);

  @override
  Box<NoteModel> get box => _mockBox;

  @override
  Future<void> ensureHiveConnected() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _kCreatedAt = DateTime(2024, 1, 1);
final _kUpdatedAt = DateTime(2024, 1, 2);

NoteModel _makeNote({
  String id = 'note-1',
  String title = 'Test Note',
  String content = 'Hello world',
  DateTime? createdAt,
  DateTime? updatedAt,
  String plainText = 'Hello world',
  String previewText = 'Hello…',
  double height = 120.0,
}) => NoteModel(
  id: id,
  title: title,
  content: content,
  createdAt: createdAt ?? _kCreatedAt,
  updatedAt: updatedAt ?? _kUpdatedAt,
  plainText: plainText,
  previewText: previewText,
  height: height,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
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

    test('returns first match when duplicate ids exist in the box', () async {
      // Hive keys are unique, but defensively verify the firstWhere behaviour.
      final first = _makeNote(id: 'note-1', title: 'First');
      final dupe = _makeNote(id: 'note-1', title: 'Duplicate');
      when(() => mockBox.values).thenReturn([first, dupe]);

      final result = await repository.getNoteById('note-1');

      expect(result?.title, equals('First'));
    });

    test('returns null (does not throw) when box.values throws', () async {
      when(() => mockBox.values).thenThrow(Exception('box error'));

      final result = await repository.getNoteById('note-1');

      expect(result, isNull);
    });

    test('preserves all fields of the returned note', () async {
      final createdAt = DateTime(2024, 3, 15);
      final updatedAt = DateTime(2024, 3, 16);
      final note = _makeNote(
        id: 'note-fields',
        title: 'Rich Note',
        content: '# Heading',
        createdAt: createdAt,
        updatedAt: updatedAt,
        plainText: 'Heading',
        previewText: 'Heading…',
        height: 250.5,
      );
      when(() => mockBox.values).thenReturn([note]);

      final result = await repository.getNoteById('note-fields');

      expect(result?.id, equals('note-fields'));
      expect(result?.title, equals('Rich Note'));
      expect(result?.content, equals('# Heading'));
      expect(result?.createdAt, equals(createdAt));
      expect(result?.updatedAt, equals(updatedAt));
      expect(result?.plainText, equals('Heading'));
      expect(result?.previewText, equals('Heading…'));
      expect(result?.height, equals(250.5));
    });
  });

  // -------------------------------------------------------------------------
  group('createNote', () {
    test('calls box.put with the note id and note', () async {
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

    test('does not throw when box.put succeeds', () async {
      final note = _makeNote();
      when(() => mockBox.put(any(), any<NoteModel>())).thenAnswer((_) async {});

      expect(() => repository.createNote(note), returnsNormally);
    });

    test('swallows exception when box.put throws', () async {
      final note = _makeNote();
      when(
        () => mockBox.put(any(), any<NoteModel>()),
      ).thenThrow(Exception('write error'));

      await expectLater(repository.createNote(note), completes);
    });

    test('uses note.id as the Hive key, not a generated key', () async {
      final note = _makeNote(id: 'custom-key-123');
      when(() => mockBox.put(any(), any<NoteModel>())).thenAnswer((_) async {});

      await repository.createNote(note);

      verify(() => mockBox.put('custom-key-123', any<NoteModel>())).called(1);
    });
  });

  // -------------------------------------------------------------------------
  group('updateNote', () {
    test('calls box.put with the note id and updated note', () async {
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

    test('overwrites an existing note (same id, new data)', () async {
      final original = _makeNote(id: 'note-1', title: 'Original');
      final updated = _makeNote(id: 'note-1', title: 'Updated');
      when(() => mockBox.put(any(), any<NoteModel>())).thenAnswer((_) async {});

      await repository.createNote(original);
      await repository.updateNote(updated);

      verify(() => mockBox.put('note-1', any<NoteModel>())).called(2);
    });

    test('does not call box.delete when updating', () async {
      final note = _makeNote(id: 'note-1');
      when(() => mockBox.put(any(), any<NoteModel>())).thenAnswer((_) async {});

      await repository.updateNote(note);

      verifyNever(() => mockBox.delete(any()));
    });

    test('swallows exception when box.put throws', () async {
      final note = _makeNote();
      when(
        () => mockBox.put(any(), any<NoteModel>()),
      ).thenThrow(HiveError('write error'));

      await expectLater(repository.updateNote(note), completes);
    });
  });

  // -------------------------------------------------------------------------
  group('deleteNote', () {
    test('calls box.delete with the correct id', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async {});

      await repository.deleteNote('note-1');

      verify(() => mockBox.delete('note-1')).called(1);
    });

    test('calls box.delete exactly once', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async {});

      await repository.deleteNote('note-1');

      verify(() => mockBox.delete(any())).called(1);
    });

    test('does not call delete with a different id', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async {});

      await repository.deleteNote('note-1');

      verifyNever(() => mockBox.delete('note-2'));
    });

    test('does not call box.put when deleting', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async {});

      await repository.deleteNote('note-1');

      verifyNever(() => mockBox.put(any(), any<NoteModel>()));
    });

    test('swallows exception when box.delete throws', () async {
      when(() => mockBox.delete(any())).thenThrow(Exception('delete error'));

      await expectLater(repository.deleteNote('note-1'), completes);
    });

    test('deleting a non-existent id does not throw', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async {});

      await expectLater(repository.deleteNote('does-not-exist'), completes);
    });
  });

  // -------------------------------------------------------------------------
  group('ensureHiveConnected', () {
    late EditorRepositoryImpl realRepo;

    setUp(() async {
      Hive.init('test_hive_${DateTime.now().microsecondsSinceEpoch}');
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(NoteModelAdapter());
      }
      realRepo = EditorRepositoryImpl();
    });

    tearDown(() async {
      if (Hive.isBoxOpen(Constants.tableName)) {
        await Hive.box<NoteModel>(Constants.tableName).close();
      }
      await Hive.deleteFromDisk();
    });

    test('opens the Hive box when it is not yet open', () async {
      expect(Hive.isBoxOpen(Constants.tableName), isFalse);

      await realRepo.ensureHiveConnected();

      expect(Hive.isBoxOpen(Constants.tableName), isTrue);
    });

    test('is idempotent — does not throw when box is already open', () async {
      await realRepo.ensureHiveConnected();

      await expectLater(realRepo.ensureHiveConnected(), completes);
      expect(Hive.isBoxOpen(Constants.tableName), isTrue);
    });

    test('box is of the correct NoteModel type after opening', () async {
      await realRepo.ensureHiveConnected();

      final box = Hive.box<NoteModel>(Constants.tableName);
      expect(box, isA<Box<NoteModel>>());
    });
  });

  // -------------------------------------------------------------------------
  group('integration — CRUD sequence (mock box)', () {
    test('create then get returns the same note', () async {
      final note = _makeNote(id: 'note-42', title: 'Integration');
      final storage = <String, NoteModel>{};

      when(() => mockBox.put(any(), any<NoteModel>())).thenAnswer((inv) async {
        storage[inv.positionalArguments[0] as String] =
            inv.positionalArguments[1] as NoteModel;
      });
      when(() => mockBox.values).thenReturn(storage.values);

      await repository.createNote(note);
      final fetched = await repository.getNoteById('note-42');

      expect(fetched, equals(note));
    });

    test('update then get returns the updated note', () async {
      final original = _makeNote(id: 'note-42', title: 'Original');
      final updated = _makeNote(id: 'note-42', title: 'Updated');
      final storage = <String, NoteModel>{};

      when(() => mockBox.put(any(), any<NoteModel>())).thenAnswer((inv) async {
        storage[inv.positionalArguments[0] as String] =
            inv.positionalArguments[1] as NoteModel;
      });
      when(() => mockBox.values).thenReturn(storage.values);

      await repository.createNote(original);
      await repository.updateNote(updated);
      final fetched = await repository.getNoteById('note-42');

      expect(fetched?.title, equals('Updated'));
    });

    test('delete then get returns null', () async {
      final note = _makeNote(id: 'note-42');
      final storage = <String, NoteModel>{'note-42': note};

      when(() => mockBox.delete(any())).thenAnswer((inv) async {
        storage.remove(inv.positionalArguments[0]);
      });
      when(() => mockBox.values).thenReturn(storage.values);

      await repository.deleteNote('note-42');
      final fetched = await repository.getNoteById('note-42');

      expect(fetched, isNull);
    });

    test('multiple notes can be created and individually retrieved', () async {
      final notes = [
        _makeNote(id: 'n1', title: 'Alpha'),
        _makeNote(id: 'n2', title: 'Beta'),
        _makeNote(id: 'n3', title: 'Gamma'),
      ];
      final storage = <String, NoteModel>{};

      when(() => mockBox.put(any(), any<NoteModel>())).thenAnswer((inv) async {
        storage[inv.positionalArguments[0] as String] =
            inv.positionalArguments[1] as NoteModel;
      });
      when(() => mockBox.values).thenReturn(storage.values);

      for (final n in notes) {
        await repository.createNote(n);
      }

      expect((await repository.getNoteById('n1'))?.title, equals('Alpha'));
      expect((await repository.getNoteById('n2'))?.title, equals('Beta'));
      expect((await repository.getNoteById('n3'))?.title, equals('Gamma'));
    });

    test('deleting one note does not affect others', () async {
      final storage = <String, NoteModel>{
        'n1': _makeNote(id: 'n1', title: 'Keep'),
        'n2': _makeNote(id: 'n2', title: 'Remove'),
      };

      when(() => mockBox.delete(any())).thenAnswer((inv) async {
        storage.remove(inv.positionalArguments[0]);
      });
      when(() => mockBox.values).thenReturn(storage.values);

      await repository.deleteNote('n2');

      expect(await repository.getNoteById('n1'), isNotNull);
      expect(await repository.getNoteById('n2'), isNull);
    });
  });
}
