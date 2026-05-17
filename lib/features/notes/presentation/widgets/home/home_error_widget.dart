import 'package:flutter/material.dart';
import 'package:mechanix_notes/core/utils/helper.dart';
import 'package:mechanix_notes/core/utils/enums.dart';

class HomeErrorView extends StatelessWidget {
  const HomeErrorView({super.key, required this.error});

  final ErrorCategory error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          localizeError(context, error),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.redAccent, fontSize: 16),
        ),
      ),
    );
  }
}
