import 'package:flutter/material.dart';

class LogosHeader extends StatelessWidget {
  final String title;

  const LogosHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
