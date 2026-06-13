import 'package:flutter/material.dart';

import '../models/legal_document.dart';

class LegalDocumentScreen extends StatelessWidget {
  final LegalDocument document;

  const LegalDocumentScreen({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF090E1A),
      appBar: AppBar(
        title: Text(document.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SelectableText(
            document.content,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.8,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ),
      ),
    );
  }
}
