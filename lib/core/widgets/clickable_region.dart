import 'package:flutter/material.dart';

class ClickableRegion extends StatelessWidget {
  final Widget child;
  const ClickableRegion({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(cursor: SystemMouseCursors.click, child: child);
  }
}
