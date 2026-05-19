import 'package:flutter/material.dart';

class SearchMessageView extends StatelessWidget {
  final String message;
  final bool isError;

  const SearchMessageView({
    super.key,
    required this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          color: isError ? Colors.red : Colors.grey,
          fontSize: 16,
        ),
      ),
    );
  }
}
