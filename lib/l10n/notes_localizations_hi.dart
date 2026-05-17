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
  String get last7Days => 'पिछले 7 दिन';

  @override
  String get failedToLoadNotes =>
      'नोट्स लोड करने में विफल। कृपया पुन: प्रयास करें।';

  @override
  String get failedToDeleteNotes =>
      'नोट्स हटाने में विफल। कृपया पुन: प्रयास करें।';

  @override
  String get noteNotFound => 'नोट नहीं मिला';

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

  @override
  String notesSelected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नोट्स चुने गए',
      one: '1 नोट चुना गया',
    );
    return '$_temp0';
  }

  @override
  String deleteNotePromptTitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नोट्स हटाएं?',
      one: '1 नोट हटाएं?',
    );
    return '$_temp0';
  }

  @override
  String deleteNotePromptSubtitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'ये नोट्स हमेशा के लिए हटा दिए जाएंगे और इन्हें वापस नहीं लाया जा सकता।',
      one: 'यह नोट हमेशा के लिए हटा दी जाएगी और इसे वापस नहीं लाया जा सकता।',
    );
    return '$_temp0';
  }

  @override
  String get justNow => 'अभी-अभी';

  @override
  String minutesAgo(num count) {
    return '$count मिनट पहले';
  }

  @override
  String hoursAgo(num count) {
    return '$count घंटे पहले';
  }

  @override
  String get failedToSaveNote => 'नोट सहेजने में विफल';
}
