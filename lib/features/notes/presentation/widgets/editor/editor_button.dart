import 'package:flutter/material.dart';
import 'package:mechanix_notes/core/widgets/clickable_region.dart';

class EditorButton extends StatelessWidget {
  final String asset;
  final VoidCallback? onPress;
  final double size;
  final bool isActive;
  final Color bgColor;
  final EdgeInsets padding;
  const EditorButton({
    super.key,
    required this.asset,
    required this.onPress,
    this.isActive = true,
    this.bgColor = Colors.transparent,
    this.padding = const EdgeInsets.all(4),
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ClickableRegion(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onPress,
        child: Container(
          color: bgColor,
          padding: padding,
          child: Image.asset(
            asset,
            width: size,
            height: size,
            color: isActive ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}
