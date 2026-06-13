import 'package:flutter/material.dart';
import '../../../app/main_shell.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import '../../../data/bible/book_catalog.dart';
import '../../../domain/entities/book.dart';
import 'chapter_screen.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  Testament testament = Testament.newTestament;

  @override
  Widget build(BuildContext context) {
    final books = BookCatalog.books
        .where((b) => b.testament == testament)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => MainShell.switchTo(0),
        ),
        title: const Text('📖 Select a Book'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<Testament>(
              segments: const [
                ButtonSegment(value: Testament.old, label: Text('Old')),
                ButtonSegment(
                    value: Testament.newTestament, label: Text('New')),
              ],
              selected: {testament},
              onSelectionChanged: (s) => setState(() => testament = s.first),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: books.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final b = books[index];
          return ListTile(
            title: Text(b.name),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => AppRouter.push(
              context,
              ChapterScreen(book: b),
              transition: AppTransitionType.slideRight,
            ),
          );
        },
      ),
    );
  }
}
