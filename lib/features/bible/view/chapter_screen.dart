import 'package:flutter/material.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import '../../../domain/entities/book.dart';
import 'verse_screen.dart';

class ChapterScreen extends StatelessWidget {
  const ChapterScreen({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${book.name} – Chapters')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: book.chapterCount,
        itemBuilder: (context, index) {
          final chapter = index + 1;
          return Card(
            elevation: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => AppRouter.push(
                context,
                VerseScreen(book: book, chapter: chapter),
                transition: AppTransitionType.slideRight,
              ),
              child: Center(
                child: Text(
                  '$chapter',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
