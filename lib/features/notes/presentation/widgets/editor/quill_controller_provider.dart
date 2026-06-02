import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// A widget that provides a [QuillController] and [FocusNode] to its children.
class QuillControllerProvider extends InheritedWidget {
  final QuillController controller;
  final FocusNode focusNode;

  const QuillControllerProvider({
    super.key,
    required this.controller,
    required this.focusNode,
    required super.child,
  });

  /// Returns the nearest [QuillControllerProvider] ancestor.
  /// Throws a [FlutterError] if none is found (fail-fast in debug).
  static QuillControllerProvider of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<QuillControllerProvider>();
    assert(
      result != null,
      'No QuillControllerProvider found in context.\n'
      'Make sure EditorScreen (or a parent) wraps its subtree with '
      'QuillControllerProvider.',
    );
    return result!;
  }

  /// Returns null if no [QuillControllerProvider] is found.
  /// Prefer [of] inside the editor subtree; use this only for optional access.
  static QuillControllerProvider? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<QuillControllerProvider>();
  }

  @override
  bool updateShouldNotify(QuillControllerProvider oldWidget) =>
      controller != oldWidget.controller || focusNode != oldWidget.focusNode;
}
