// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'notes_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get notes => 'नोट्स';

  @override
  String get noNotesFound => 'कोई नोट्स नहीं मिले';

  @override
  String get recent => 'हाल ही में';

  @override
  String get today => 'आज';

  @override
  String get yesterday => 'कल';

  @override
  String get thisWeek => 'इस सप्ताह';

  @override
  String get lastWeek => 'पिछले सप्ताह';

  @override
  String get thisMonth => 'इस महीने';

  @override
  String get lastMonth => 'पिछले महीने';

  @override
  String get startWriting => 'लिखना शुरू करें…';

  @override
  String get title => 'शीर्षक';

  @override
  String get undo => 'पूर्ववत करें';

  @override
  String get redo => 'फिर से करें';

  @override
  String get somethingWentWrong => 'कुछ गलत हो गया';

  @override
  String get goBack => 'वापस जाएं';

  @override
  String deleteNotePrompt(String noteTitle) {
    return '\'$noteTitle\' हटाएं?';
  }

  @override
  String get cancel => 'रद्द करें';

  @override
  String get saveChanges => 'परिवर्तन सहेजें';

  @override
  String get deleteNoteSubtitle =>
      'यह नोट हमेशा के लिए हटा दी जाएगी और इसे वापस नहीं लाया जा सकता।';

  @override
  String get delete => 'हटाएं';
}
