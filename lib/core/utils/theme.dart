import 'package:flutter/material.dart';
import 'package:mechanix_notes/core/utils/colors.dart';

class AppTheme {
  static final dark = ThemeData.dark(useMaterial3: true).copyWith(
    textTheme: _appTextTheme(),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.linux: CupertinoPageTransitionsBuilder()},
    ),
    scrollbarTheme: const ScrollbarThemeData(
      radius: Radius.circular(4),
      thickness: WidgetStatePropertyAll(4),
      thumbColor: WidgetStatePropertyAll(NotesColors.timeLabelColor),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.white),
  );

  static final light = ThemeData.light(useMaterial3: true).copyWith(
    textTheme: _appTextTheme(),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.linux: CupertinoPageTransitionsBuilder()},
    ),
    scrollbarTheme: const ScrollbarThemeData(
      radius: Radius.circular(4),
      thickness: WidgetStatePropertyAll(4),
      thumbColor: WidgetStatePropertyAll(NotesColors.timeLabelColor),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.white),
  );
}

TextTheme _appTextTheme() => ThemeData.dark(useMaterial3: true).textTheme
    .apply(fontFamily: "Sora")
    .copyWith(
      bodySmall: const TextStyle(color: Colors.white, fontSize: 16),
      titleLarge: const TextStyle(
        color: NotesColors.appTitleColor,
        fontSize: 24,
      ),
      titleMedium: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: const TextStyle(
        color: NotesColors.timeLabelColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      displayMedium: const TextStyle(color: Colors.redAccent, fontSize: 16),
    );
