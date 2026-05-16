import 'package:flutter/material.dart';
import 'package:mechanix_notes/core/utils/colors.dart';

class AppTheme {
  static final dark = ThemeData.dark(useMaterial3: true).copyWith(
    textTheme: ThemeData.dark(
      useMaterial3: true,
    ).textTheme.apply(fontFamily: "Sora"),
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
    textTheme: ThemeData.light(
      useMaterial3: true,
    ).textTheme.apply(fontFamily: "Sora"),
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
