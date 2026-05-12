import 'dart:convert';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_quill/flutter_quill.dart' show Document;
import 'package:mechanix_notes/features/notes/bloc/editor/editor_bloc.dart';
import 'package:mechanix_notes/features/notes/data/models/note_model.dart';
import 'package:mechanix_notes/features/notes/data/repository/editor_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockEditorRepository extends Mock implements EditorRepository {}

// ─── Helpers ─────────────────────────────────────────────────────────────────

const kTestNoteId = 'test-note-id-123';
const kTestTitle = 'Test Note Title';
const kEmptyDelta = '[{"insert":"\\n"}]';
const kSomeDelta = '[{"insert":"Hello World\\n"}]';
const kSomePlainText = 'Hello World\n';

NoteModel makeNote({
  String id = kTestNoteId,
  String title = kTestTitle,
  String content = kSomeDelta,
  String plainText = kSomePlainText,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime(2024, 1, 1);
  return NoteModel(
    id: id,
    title: title,
    content: content,
    plainText: plainText,
    previewText: plainText.length > 120
        ? '${plainText.substring(0, 120)}…'
        : plainText,
    height: 104.0,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

// ─── Main ─────────────────────────────────────────────────────────────────────
class FakeNoteModel extends Fake implements NoteModel {}

void main() {
  late MockEditorRepository repository;
  setUpAll(() {
    registerFallbackValue(FakeNoteModel());
  });
  setUp(() {
    repository = MockEditorRepository();
  });

  EditorBloc buildBloc() => EditorBloc(repository);

  // ════════════════════════════════════════════════════════════════════════════
  // Initial state
  // ════════════════════════════════════════════════════════════════════════════

  group('Initial state', () {
    test('is EditorInitial', () {
      expect(buildBloc().state, isA<EditorInitial>());
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // EditorInitialised — CREATE mode (no noteId)
  // ════════════════════════════════════════════════════════════════════════════

  group('EditorInitialised — create mode', () {
    blocTest<EditorBloc, EditorState>(
      'emits EditorLoaded with empty title, blank document, isNewNote=true',
      build: buildBloc,
      act: (bloc) => bloc.add(EditorInitialised()),
      expect: () => [
        isA<EditorLoaded>()
            .having((s) => s.title, 'title', '')
            .having((s) => s.isNewNote, 'isNewNote', true)
            .having((s) => s.isContentLoading, 'isContentLoading', false)
            .having((s) => s.quillDocument, 'quillDocument', isNotNull),
      ],
      verify: (_) => verifyNever(() => repository.getNoteById(any())),
    );

    blocTest<EditorBloc, EditorState>(
      'generated noteId is a valid non-empty UUID',
      build: buildBloc,
      act: (bloc) => bloc.add(EditorInitialised()),
      verify: (bloc) {
        final loaded = bloc.state as EditorLoaded;
        expect(loaded.noteId, isNotEmpty);
        // UUID v4 format: 8-4-4-4-12 hex chars
        final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          caseSensitive: false,
        );
        expect(uuidRegex.hasMatch(loaded.noteId), isTrue);
      },
    );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // EditorInitialised — EDIT mode (noteId provided)
  // ════════════════════════════════════════════════════════════════════════════

  group('EditorInitialised — edit mode', () {
    blocTest<EditorBloc, EditorState>(
      'emits loading shell then EditorLoaded with note data',
      build: buildBloc,
      setUp: () {
        when(
          () => repository.getNoteById(kTestNoteId),
        ).thenAnswer((_) async => makeNote());
      },
      act: (bloc) => bloc.add(
        EditorInitialised(noteId: kTestNoteId, noteTitle: kTestTitle),
      ),
      wait: const Duration(
        milliseconds: 300,
      ), // ← give compute() time to finish
      expect: () => [
        // 1st: loading shell
        isA<EditorLoaded>()
            .having((s) => s.noteId, 'noteId', kTestNoteId)
            .having((s) => s.isContentLoading, 'isContentLoading', true)
            .having((s) => s.isNewNote, 'isNewNote', false),
        // 2nd: fully loaded
        isA<EditorLoaded>()
            .having((s) => s.noteId, 'noteId', kTestNoteId)
            .having((s) => s.title, 'title', kTestTitle)
            .having((s) => s.isContentLoading, 'isContentLoading', false)
            .having((s) => s.quillDocument, 'quillDocument', isNotNull)
            .having((s) => s.isNewNote, 'isNewNote', false),
      ],
    );

    blocTest<EditorBloc, EditorState>(
      'uses noteTitle override instead of note.title when provided',
      build: buildBloc,
      setUp: () {
        when(
          () => repository.getNoteById(kTestNoteId),
        ).thenAnswer((_) async => makeNote(title: 'DB Title'));
      },
      act: (bloc) => bloc.add(
        EditorInitialised(noteId: kTestNoteId, noteTitle: 'Override Title'),
      ),
      verify: (bloc) {
        final loaded = bloc.state as EditorLoaded;
        expect(loaded.title, 'Override Title');
      },
    );

    blocTest<EditorBloc, EditorState>(
      'falls back to note.title when noteTitle override is null',
      build: buildBloc,
      setUp: () {
        when(
          () => repository.getNoteById(kTestNoteId),
        ).thenAnswer((_) async => makeNote(title: 'DB Title'));
      },
      act: (bloc) => bloc.add(EditorInitialised(noteId: kTestNoteId)),
      wait: const Duration(milliseconds: 300), // ← wait for compute + repo
      verify: (bloc) {
        final loaded = bloc.state as EditorLoaded;
        expect(loaded.title, 'DB Title');
      },
    );

    blocTest<EditorBloc, EditorState>(
      'emits EditorFailure when note is not found',
      build: buildBloc,
      setUp: () {
        when(
          () => repository.getNoteById(kTestNoteId),
        ).thenAnswer((_) async => null);
      },
      act: (bloc) => bloc.add(EditorInitialised(noteId: kTestNoteId)),
      expect: () => [
        isA<EditorLoaded>().having((s) => s.isContentLoading, 'loading', true),
        isA<EditorFailure>().having(
          (s) => s.message,
          'message',
          'Note not found.',
        ),
      ],
    );

    blocTest<EditorBloc, EditorState>(
      'handles malformed content JSON gracefully (falls back to empty doc)',
      build: buildBloc,
      setUp: () {
        when(
          () => repository.getNoteById(kTestNoteId),
        ).thenAnswer((_) async => makeNote(content: 'NOT_VALID_JSON'));
      },
      act: (bloc) => bloc.add(EditorInitialised(noteId: kTestNoteId)),
      wait: const Duration(milliseconds: 300), // ← wait for compute + repo
      verify: (bloc) {
        // Should still land in EditorLoaded with a non-null document
        expect(bloc.state, isA<EditorLoaded>());
        final loaded = bloc.state as EditorLoaded;
        expect(loaded.quillDocument, isNotNull);
      },
    );
    // GAP: valid JSON that is not a List (e.g. a Map) → falls back to Document()
    blocTest<EditorBloc, EditorState>(
      'handles non-List JSON content gracefully (falls back to empty doc)',
      build: buildBloc,
      setUp: () {
        // Valid JSON but not a List — cast to List<dynamic> will throw
        when(
          () => repository.getNoteById(kTestNoteId),
        ).thenAnswer((_) async => makeNote(content: '{"key":"value"}'));
      },
      act: (bloc) => bloc.add(
        EditorInitialised(noteId: kTestNoteId, noteTitle: kTestTitle),
      ),
      wait: const Duration(milliseconds: 300),
      verify: (bloc) {
        expect(bloc.state, isA<EditorLoaded>());
        final loaded = bloc.state as EditorLoaded;
        expect(loaded.quillDocument, isNotNull);
        expect(loaded.isContentLoading, false);
      },
    );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // EditorTitleChanged
  // ════════════════════════════════════════════════════════════════════════════

  group('EditorTitleChanged', () {
    blocTest<EditorBloc, EditorState>(
      'updates title in EditorLoaded',
      build: buildBloc,
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: '',
        quillDocument: Document(),
        isNewNote: true,
      ),
      act: (bloc) => bloc.add(EditorTitleChanged('New Title')),
      expect: () => [
        isA<EditorLoaded>().having((s) => s.title, 'title', 'New Title'),
      ],
    );

    blocTest<EditorBloc, EditorState>(
      'is a no-op when state is not EditorLoaded',
      build: buildBloc,
      // state is EditorInitial by default
      act: (bloc) => bloc.add(EditorTitleChanged('Ignored')),
      expect: () => [],
    );

    blocTest<EditorBloc, EditorState>(
      'handles empty string title',
      build: buildBloc,
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: 'Some Title',
        quillDocument: Document(),
        isNewNote: false,
      ),
      act: (bloc) => bloc.add(EditorTitleChanged('')),
      expect: () => [isA<EditorLoaded>().having((s) => s.title, 'title', '')],
    );

    blocTest<EditorBloc, EditorState>(
      'does not reset other fields when title changes',
      build: buildBloc,
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: 'Old',
        quillDocument: Document(),
        isNewNote: false,
        activeToolbar: EditorToolbar.textStyle,
      ),
      act: (bloc) => bloc.add(EditorTitleChanged('New')),
      verify: (bloc) {
        final s = bloc.state as EditorLoaded;
        expect(s.activeToolbar, EditorToolbar.textStyle);
        expect(s.isNewNote, false);
        expect(s.noteId, kTestNoteId);
      },
    );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // EditorToolbarToggled
  // ════════════════════════════════════════════════════════════════════════════

  group('EditorToolbarToggled', () {
    blocTest<EditorBloc, EditorState>(
      'activates a toolbar when none is active',
      build: buildBloc,
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        activeToolbar: EditorToolbar.none,
        isNewNote: false,
      ),
      act: (bloc) => bloc.add(EditorToolbarToggled(EditorToolbar.textStyle)),
      expect: () => [
        isA<EditorLoaded>().having(
          (s) => s.activeToolbar,
          'toolbar',
          EditorToolbar.textStyle,
        ),
      ],
    );

    blocTest<EditorBloc, EditorState>(
      'closes toolbar when same toolbar toggled again',
      build: buildBloc,
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        activeToolbar: EditorToolbar.textStyle,
        isNewNote: false,
      ),
      act: (bloc) => bloc.add(EditorToolbarToggled(EditorToolbar.textStyle)),
      expect: () => [
        isA<EditorLoaded>().having(
          (s) => s.activeToolbar,
          'toolbar',
          EditorToolbar.none,
        ),
      ],
    );

    blocTest<EditorBloc, EditorState>(
      'switches from one toolbar to another',
      build: buildBloc,
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        activeToolbar: EditorToolbar.textStyle,
        isNewNote: false,
      ),
      act: (bloc) => bloc.add(EditorToolbarToggled(EditorToolbar.menu)),
      expect: () => [
        isA<EditorLoaded>().having(
          (s) => s.activeToolbar,
          'toolbar',
          EditorToolbar.menu,
        ),
      ],
    );

    for (final toolbar in EditorToolbar.values.where(
      (t) => t != EditorToolbar.none,
    )) {
      blocTest<EditorBloc, EditorState>(
        'can activate toolbar: $toolbar',
        build: buildBloc,
        seed: () => EditorLoaded(
          noteId: kTestNoteId,
          title: kTestTitle,
          activeToolbar: EditorToolbar.none,
          isNewNote: false,
        ),
        act: (bloc) => bloc.add(EditorToolbarToggled(toolbar)),
        verify: (bloc) {
          expect((bloc.state as EditorLoaded).activeToolbar, toolbar);
        },
      );
    }

    blocTest<EditorBloc, EditorState>(
      'is a no-op when state is not EditorLoaded',
      build: buildBloc,
      act: (bloc) => bloc.add(EditorToolbarToggled(EditorToolbar.menu)),
      expect: () => [],
    );
    // GAP: toggling EditorToolbar.none when already none → stays none
    blocTest<EditorBloc, EditorState>(
      'toggling none toolbar when already none keeps it none',
      build: buildBloc,
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        activeToolbar: EditorToolbar.none,
        isNewNote: false,
      ),
      act: (bloc) => bloc.add(EditorToolbarToggled(EditorToolbar.none)),
      expect: () => [
        isA<EditorLoaded>().having(
          (s) => s.activeToolbar,
          'toolbar',
          EditorToolbar.none,
        ),
      ],
    );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // EditorSaveRequested — new note
  // ════════════════════════════════════════════════════════════════════════════

  group('EditorSaveRequested — new note', () {
    blocTest<EditorBloc, EditorState>(
      'discards a new note that has empty title and empty body',
      build: buildBloc,
      setUp: () {
        when(() => repository.getNoteById(any())).thenAnswer((_) async => null);
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: '',
        quillDocument: Document(),
        isNewNote: true,
      ),
      act: (bloc) => bloc.add(
        EditorSaveRequested(content: jsonDecode(kEmptyDelta), plainText: '   '),
      ),
      expect: () => [isA<EditorDiscarded>()],
      verify: (_) => verifyNever(() => repository.createNote(any())),
    );

    blocTest<EditorBloc, EditorState>(
      'saves new note when title is non-empty even if body is blank',
      build: buildBloc,
      setUp: () {
        when(() => repository.getNoteById(any())).thenAnswer((_) async => null);
        when(() => repository.createNote(any())).thenAnswer((_) async {});
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        quillDocument: Document(),
        isNewNote: true,
      ),
      act: (bloc) =>
          bloc.add(EditorSaveRequested(content: jsonDecode(kEmptyDelta), plainText: '')),
      expect: () => [
        isA<EditorLoaded>().having((s) => s.isSaving, 'isSaving', true),
        isA<EditorSaveSuccess>().having((s) => s.noteId, 'noteId', kTestNoteId),
      ],
      verify: (_) => verify(() => repository.createNote(any())).called(1),
    );

    blocTest<EditorBloc, EditorState>(
      'saves new note when body is non-empty even if title is blank',
      build: buildBloc,
      setUp: () {
        when(() => repository.getNoteById(any())).thenAnswer((_) async => null);
        when(() => repository.createNote(any())).thenAnswer((_) async {});
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: '',
        quillDocument: Document(),
        isNewNote: true,
      ),
      act: (bloc) => bloc.add(
        EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: kSomePlainText),
      ),
      expect: () => [
        isA<EditorLoaded>().having((s) => s.isSaving, 'isSaving', true),
        isA<EditorSaveSuccess>(),
      ],
    );

    blocTest<EditorBloc, EditorState>(
      'calls createNote (not updateNote) for a brand-new note',
      build: buildBloc,
      setUp: () {
        when(() => repository.getNoteById(any())).thenAnswer((_) async => null);
        when(() => repository.createNote(any())).thenAnswer((_) async {});
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        quillDocument: Document(),
        isNewNote: true,
      ),
      act: (bloc) => bloc.add(
        EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: kSomePlainText),
      ),
      verify: (_) {
        verify(() => repository.createNote(any())).called(1);
        verifyNever(() => repository.updateNote(any()));
      },
    );

    blocTest<EditorBloc, EditorState>(
      'truncates previewText to 120 chars with ellipsis for long content',
      build: buildBloc,
      setUp: () {
        when(() => repository.getNoteById(any())).thenAnswer((_) async => null);
        when(
          () => repository.createNote(captureAny()),
        ).thenAnswer((_) async {});
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        quillDocument: Document(),
        isNewNote: true,
      ),
      act: (bloc) {
        final longText = 'A' * 200;
        bloc.add(
          EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: longText),
        );
      },
      verify: (_) {
        final captured = verify(
          () => repository.createNote(captureAny()),
        ).captured;
        final note = captured.first as NoteModel;
        expect(note.previewText.length, 121); // 120 chars + '…'
        expect(note.previewText.endsWith('…'), isTrue);
      },
    );

    blocTest<EditorBloc, EditorState>(
      'emits EditorFailure when createNote throws',
      build: buildBloc,
      setUp: () {
        when(() => repository.getNoteById(any())).thenAnswer((_) async => null);
        when(
          () => repository.createNote(any()),
        ).thenThrow(Exception('DB error'));
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        quillDocument: Document(),
        isNewNote: true,
      ),
      act: (bloc) => bloc.add(
        EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: kSomePlainText),
      ),
      expect: () => [
        isA<EditorLoaded>().having((s) => s.isSaving, 'isSaving', true),
        isA<EditorFailure>().having(
          (s) => s.message,
          'message',
          'Failed to save note. Please try again.',
        ),
      ],
    );
    // GAP: getNoteById throws during save → should emit EditorFailure
    blocTest<EditorBloc, EditorState>(
      'emits EditorFailure when getNoteById throws during save',
      build: buildBloc,
      setUp: () {
        when(
          () => repository.getNoteById(any()),
        ).thenThrow(Exception('DB connection lost'));
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        quillDocument: Document(),
        isNewNote: true,
      ),
      act: (bloc) => bloc.add(
        EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: kSomePlainText),
      ),
      expect: () => [
        // isSaving is never emitted — getNoteById throws before that line
        isA<EditorFailure>().having(
          (s) => s.message,
          'message',
          'Failed to save note. Please try again.',
        ),
      ],
      verify: (_) => verifyNever(() => repository.createNote(any())),
    );

    // GAP: plainText exactly 120 chars → previewText NOT truncated (no ellipsis)
    blocTest<EditorBloc, EditorState>(
      'does NOT truncate previewText when plainText is exactly 120 chars',
      build: buildBloc,
      setUp: () {
        when(() => repository.getNoteById(any())).thenAnswer((_) async => null);
        when(
          () => repository.createNote(captureAny()),
        ).thenAnswer((_) async {});
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        quillDocument: Document(),
        isNewNote: true,
      ),
      act: (bloc) {
        final exactText = 'A' * 120; // exactly at boundary — must NOT truncate
        bloc.add(
          EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: exactText),
        );
      },
      verify: (_) {
        final captured = verify(
          () => repository.createNote(captureAny()),
        ).captured;
        final note = captured.first as NoteModel;
        expect(note.previewText.endsWith('…'), isFalse);
        expect(note.previewText.length, 120);
      },
    );

    // GAP: plainText 121 chars → previewText IS truncated (first > 120 case)
    blocTest<EditorBloc, EditorState>(
      'truncates previewText when plainText is 121 chars',
      build: buildBloc,
      setUp: () {
        when(() => repository.getNoteById(any())).thenAnswer((_) async => null);
        when(
          () => repository.createNote(captureAny()),
        ).thenAnswer((_) async {});
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        quillDocument: Document(),
        isNewNote: true,
      ),
      act: (bloc) {
        final justOver = 'A' * 121;
        bloc.add(
          EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: justOver),
        );
      },
      verify: (_) {
        final captured = verify(
          () => repository.createNote(captureAny()),
        ).captured;
        final note = captured.first as NoteModel;
        expect(note.previewText.endsWith('…'), isTrue);
        expect(note.previewText.length, 121); // 120 + '…'
      },
    );

    // GAP: _estimateHeight — short text (1 line)
    blocTest<EditorBloc, EditorState>(
      'height is correct for short single-line text',
      build: buildBloc,
      setUp: () {
        when(() => repository.getNoteById(any())).thenAnswer((_) async => null);
        when(
          () => repository.createNote(captureAny()),
        ).thenAnswer((_) async {});
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        quillDocument: Document(),
        isNewNote: true,
      ),
      act: (bloc) {
        // 10 chars → ceil(10/60)=1 line → 1*24 + 80 = 104
        bloc.add(
          EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: 'Short'),
        );
      },
      verify: (_) {
        final captured = verify(
          () => repository.createNote(captureAny()),
        ).captured;
        final note = captured.first as NoteModel;
        expect(note.height, 104.0); // 1 line * 24 + 80
      },
    );

    // GAP: _estimateHeight — very long text clamped to 20 lines
    blocTest<EditorBloc, EditorState>(
      'height is clamped at 20 lines for very long text',
      build: buildBloc,
      setUp: () {
        when(() => repository.getNoteById(any())).thenAnswer((_) async => null);
        when(
          () => repository.createNote(captureAny()),
        ).thenAnswer((_) async {});
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        quillDocument: Document(),
        isNewNote: true,
      ),
      act: (bloc) {
        // 60*21 = 1260 chars → ceil(1260/60)=21 lines → clamped to 20 → 20*24+80=560
        final longText = 'A' * (60 * 21);
        bloc.add(
          EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: longText),
        );
      },
      verify: (_) {
        final captured = verify(
          () => repository.createNote(captureAny()),
        ).captured;
        final note = captured.first as NoteModel;
        expect(note.height, 560.0); // 20 lines * 24 + 80
      },
    );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // EditorSaveRequested — existing note
  // ════════════════════════════════════════════════════════════════════════════

  group('EditorSaveRequested — existing note', () {
    blocTest<EditorBloc, EditorState>(
      'discards when nothing changed',
      build: buildBloc,
      setUp: () {
        when(() => repository.getNoteById(kTestNoteId)).thenAnswer(
          (_) async => makeNote(title: kTestTitle, content: kSomeDelta),
        );
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        quillDocument: Document(),
        isNewNote: false,
      ),
      act: (bloc) => bloc.add(
        EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: kSomePlainText),
      ),
      expect: () => [isA<EditorDiscarded>()],
      verify: (_) {
        verifyNever(() => repository.updateNote(any()));
        verifyNever(() => repository.createNote(any()));
      },
    );

    blocTest<EditorBloc, EditorState>(
      'calls updateNote when title changed',
      build: buildBloc,
      setUp: () {
        when(() => repository.getNoteById(kTestNoteId)).thenAnswer(
          (_) async => makeNote(title: 'Old Title', content: kSomeDelta),
        );
        when(() => repository.updateNote(any())).thenAnswer((_) async {});
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: 'New Title', // changed
        quillDocument: Document(),
        isNewNote: false,
      ),
      act: (bloc) => bloc.add(
        EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: kSomePlainText),
      ),
      expect: () => [
        isA<EditorLoaded>().having((s) => s.isSaving, 'isSaving', true),
        isA<EditorSaveSuccess>(),
      ],
      verify: (_) {
        verify(() => repository.updateNote(any())).called(1);
        verifyNever(() => repository.createNote(any()));
      },
    );

    blocTest<EditorBloc, EditorState>(
      'calls updateNote when content changed',
      build: buildBloc,
      setUp: () {
        when(() => repository.getNoteById(kTestNoteId)).thenAnswer(
          (_) async => makeNote(title: kTestTitle, content: kEmptyDelta),
        );
        when(() => repository.updateNote(any())).thenAnswer((_) async {});
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        quillDocument: Document(),
        isNewNote: false,
      ),
      act: (bloc) => bloc.add(
        EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: kSomePlainText),
      ),
      expect: () => [
        isA<EditorLoaded>().having((s) => s.isSaving, 'isSaving', true),
        isA<EditorSaveSuccess>(),
      ],
      verify: (_) => verify(() => repository.updateNote(any())).called(1),
    );

    blocTest<EditorBloc, EditorState>(
      'preserves original createdAt when updating',
      build: buildBloc,
      setUp: () {
        final original = makeNote(createdAt: DateTime(2020, 6, 15));
        when(
          () => repository.getNoteById(kTestNoteId),
        ).thenAnswer((_) async => original);
        when(
          () => repository.updateNote(captureAny()),
        ).thenAnswer((_) async {});
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: 'Different Title',
        quillDocument: Document(),
        isNewNote: false,
      ),
      act: (bloc) => bloc.add(
        EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: kSomePlainText),
      ),
      verify: (_) {
        final captured = verify(
          () => repository.updateNote(captureAny()),
        ).captured;
        final saved = captured.first as NoteModel;
        expect(saved.createdAt, DateTime(2020, 6, 15));
      },
    );

    blocTest<EditorBloc, EditorState>(
      'updatedAt is newer than createdAt after update',
      build: buildBloc,
      setUp: () {
        final original = makeNote(createdAt: DateTime(2020, 1, 1));
        when(
          () => repository.getNoteById(kTestNoteId),
        ).thenAnswer((_) async => original);
        when(
          () => repository.updateNote(captureAny()),
        ).thenAnswer((_) async {});
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: 'Updated',
        quillDocument: Document(),
        isNewNote: false,
      ),
      act: (bloc) => bloc.add(
        EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: kSomePlainText),
      ),
      verify: (_) {
        final captured = verify(
          () => repository.updateNote(captureAny()),
        ).captured;
        final saved = captured.first as NoteModel;
        expect(saved.updatedAt.isAfter(saved.createdAt), isTrue);
      },
    );

    blocTest<EditorBloc, EditorState>(
      'emits EditorFailure when updateNote throws',
      build: buildBloc,
      setUp: () {
        when(
          () => repository.getNoteById(kTestNoteId),
        ).thenAnswer((_) async => makeNote(title: 'Old', content: kEmptyDelta));
        when(
          () => repository.updateNote(any()),
        ).thenThrow(Exception('Network error'));
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: 'New',
        quillDocument: Document(),
        isNewNote: false,
      ),
      act: (bloc) => bloc.add(
        EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: kSomePlainText),
      ),
      expect: () => [
        isA<EditorLoaded>().having((s) => s.isSaving, 'isSaving', true),
        isA<EditorFailure>(),
      ],
    );

    blocTest<EditorBloc, EditorState>(
      'is a no-op when state is not EditorLoaded',
      build: buildBloc,
      act: (bloc) => bloc.add(
        EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: kSomePlainText),
      ),
      expect: () => [],
    );
    // GAP: isNewNote=false but getNoteById returns null → should createNote
    blocTest<EditorBloc, EditorState>(
      'calls createNote when isNewNote=false but note no longer exists in DB',
      build: buildBloc,
      setUp: () {
        // Simulates a race condition / deleted note
        when(
          () => repository.getNoteById(kTestNoteId),
        ).thenAnswer((_) async => null);
        when(() => repository.createNote(any())).thenAnswer((_) async {});
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        quillDocument: Document(),
        isNewNote: false, // flag says edit, but DB has nothing
      ),
      act: (bloc) => bloc.add(
        EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: kSomePlainText),
      ),
      expect: () => [
        isA<EditorLoaded>().having((s) => s.isSaving, 'isSaving', true),
        isA<EditorSaveSuccess>(),
      ],
      verify: (_) {
        verify(() => repository.createNote(any())).called(1);
        verifyNever(() => repository.updateNote(any()));
      },
    );
    // GAP: getNoteById throws during update save → EditorFailure
    blocTest<EditorBloc, EditorState>(
      'emits EditorFailure when getNoteById throws during existing note save',
      build: buildBloc,
      setUp: () {
        when(
          () => repository.getNoteById(any()),
        ).thenThrow(Exception('Timeout'));
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        quillDocument: Document(),
        isNewNote: false,
      ),
      act: (bloc) => bloc.add(
        EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: kSomePlainText),
      ),
      expect: () => [
        // same reason — throws before isSaving is emitted
        isA<EditorFailure>(),
      ],
    );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // EditorDeleteRequested
  // ════════════════════════════════════════════════════════════════════════════

  group('EditorDeleteRequested', () {
    blocTest<EditorBloc, EditorState>(
      'emits EditorDeleteSuccess after successful delete',
      build: buildBloc,
      setUp: () {
        when(() => repository.deleteNote(kTestNoteId)).thenAnswer((_) async {});
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        quillDocument: Document(),
        isNewNote: false,
      ),
      act: (bloc) => bloc.add(EditorDeleteRequested()),
      expect: () => [
        isA<EditorDeleteSuccess>().having(
          (s) => s.noteId,
          'noteId',
          kTestNoteId,
        ),
      ],
      verify: (_) => verify(() => repository.deleteNote(kTestNoteId)).called(1),
    );

    blocTest<EditorBloc, EditorState>(
      'emits EditorFailure when deleteNote throws',
      build: buildBloc,
      setUp: () {
        when(
          () => repository.deleteNote(any()),
        ).thenThrow(Exception('Delete failed'));
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: kTestTitle,
        quillDocument: Document(),
        isNewNote: false,
      ),
      act: (bloc) => bloc.add(EditorDeleteRequested()),
      expect: () => [
        isA<EditorFailure>().having(
          (s) => s.message,
          'message',
          'Failed to delete note.',
        ),
      ],
    );

    blocTest<EditorBloc, EditorState>(
      'is a no-op when state is not EditorLoaded',
      build: buildBloc,
      act: (bloc) => bloc.add(EditorDeleteRequested()),
      expect: () => [],
      verify: (_) => verifyNever(() => repository.deleteNote(any())),
    );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // EditorLoaded.copyWith — unit tests
  // ════════════════════════════════════════════════════════════════════════════

  group('EditorLoaded.copyWith', () {
    final base = EditorLoaded(
      noteId: kTestNoteId,
      title: kTestTitle,
      quillDocument: Document(),
      isContentLoading: false,
      isSaving: false,
      activeToolbar: EditorToolbar.none,
      isNewNote: false,
    );

    test('returns identical values when nothing overridden', () {
      final copy = base.copyWith();
      expect(copy.noteId, base.noteId);
      expect(copy.title, base.title);
      expect(copy.isContentLoading, base.isContentLoading);
      expect(copy.isSaving, base.isSaving);
      expect(copy.activeToolbar, base.activeToolbar);
      expect(copy.isNewNote, base.isNewNote);
    });

    test('overrides only supplied fields', () {
      final copy = base.copyWith(title: 'Changed', isSaving: true);
      expect(copy.title, 'Changed');
      expect(copy.isSaving, true);
      // untouched
      expect(copy.noteId, base.noteId);
      expect(copy.activeToolbar, base.activeToolbar);
    });

    test('can set activeToolbar to every enum value', () {
      for (final t in EditorToolbar.values) {
        final copy = base.copyWith(activeToolbar: t);
        expect(copy.activeToolbar, t);
      }
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // Edge cases & sequential event chains
  // ════════════════════════════════════════════════════════════════════════════

  group('Edge cases', () {
    blocTest<EditorBloc, EditorState>(
      'title → toolbar toggle → save flows correctly in sequence',
      build: buildBloc,
      setUp: () {
        when(() => repository.getNoteById(any())).thenAnswer((_) async => null);
        when(() => repository.createNote(any())).thenAnswer((_) async {});
      },
      seed: () => EditorLoaded(
        noteId: kTestNoteId,
        title: '',
        quillDocument: Document(),
        isNewNote: true,
      ),
      act: (bloc) async {
        bloc.add(EditorTitleChanged('Chained Title'));
        bloc.add(EditorToolbarToggled(EditorToolbar.options));
        bloc.add(
          EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: kSomePlainText),
        );
      },
      expect: () => [
        isA<EditorLoaded>().having((s) => s.title, 'title', 'Chained Title'),
        isA<EditorLoaded>().having(
          (s) => s.activeToolbar,
          'toolbar',
          EditorToolbar.options,
        ),
        isA<EditorLoaded>().having((s) => s.isSaving, 'isSaving', true),
        isA<EditorSaveSuccess>(),
      ],
    );

    blocTest<EditorBloc, EditorState>(
      'multiple title changes only keeps last value',
      build: buildBloc,
      seed: () => EditorLoaded(noteId: kTestNoteId, title: '', isNewNote: true),
      act: (bloc) {
        bloc.add(EditorTitleChanged('A'));
        bloc.add(EditorTitleChanged('AB'));
        bloc.add(EditorTitleChanged('ABC'));
      },
      verify: (bloc) {
        expect((bloc.state as EditorLoaded).title, 'ABC');
      },
    );

    blocTest<EditorBloc, EditorState>(
      'getNoteById is only called once per initialise in edit mode',
      build: buildBloc,
      setUp: () {
        when(
          () => repository.getNoteById(kTestNoteId),
        ).thenAnswer((_) async => makeNote());
      },
      act: (bloc) => bloc.add(EditorInitialised(noteId: kTestNoteId)),
      verify: (_) =>
          verify(() => repository.getNoteById(kTestNoteId)).called(1),
    );
    // GAP: two consecutive saves on the same new note — 2nd should updateNote
    blocTest<EditorBloc, EditorState>(
      'second save after create calls updateNote not createNote',
      build: buildBloc,
      setUp: () {
        when(() => repository.getNoteById(any())).thenAnswer((_) async => null);
        when(() => repository.createNote(any())).thenAnswer((_) async {});
        // After first save, repo returns the note for subsequent lookups
        when(() => repository.updateNote(any())).thenAnswer((_) async {});
      },
      act: (bloc) async {
        // Seed into loaded state and fire two saves
        bloc.emit(
          EditorLoaded(
            noteId: kTestNoteId,
            title: kTestTitle,
            quillDocument: Document(),
            isNewNote: true,
          ),
        );

        bloc.add(
          EditorSaveRequested(content: jsonDecode(kSomeDelta), plainText: kSomePlainText),
        );

        await Future<void>.delayed(Duration.zero);

        // After first save succeeds the bloc emits EditorSaveSuccess.
        // The UI would re-initialise with the same noteId (isNewNote=false).
        // Simulate that by re-seeding via a second initialise with the persisted note.
        when(
          () => repository.getNoteById(kTestNoteId),
        ).thenAnswer((_) async => makeNote());

        bloc.add(EditorInitialised(noteId: kTestNoteId, noteTitle: kTestTitle));
      },
      wait: const Duration(milliseconds: 300),
      verify: (_) {
        verify(() => repository.createNote(any())).called(1);
      },
    );
  });
}
