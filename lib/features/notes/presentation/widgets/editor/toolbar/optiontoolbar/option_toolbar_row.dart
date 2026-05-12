import 'package:flutter/material.dart';
import 'package:mechanix_notes/core/widgets/clickable_region.dart';

class OptionToolbarRow extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;

  const OptionToolbarRow({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClickableRegion(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF2D2D2D), width: 1)),
          ),
          child: Row(
            children: [
              Image.asset(icon, color: Colors.white, height: 24, width: 24),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
