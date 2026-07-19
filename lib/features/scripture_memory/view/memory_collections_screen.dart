import 'package:flutter/material.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import '../../../shared/state/app_state.dart';
import '../model/memory_collection.dart';
import '../repository/memory_collection_repository.dart';
import 'memory_collection_detail_screen.dart';

class MemoryCollectionsScreen extends StatelessWidget {
  MemoryCollectionsScreen({super.key});

  final MemoryCollectionRepository _repository = MemoryCollectionRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Collections')),
      body: FutureBuilder<List<MemoryCollection>>(
        future: _repository.loadCollections(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Collections could not be loaded.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final memoryVerses = AppScope.of(context).memoryVerseRepo.list();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final collection = snapshot.data![index];
              final added = memoryVerses
                  .where(
                    (verse) => verse.collectionIds.contains(collection.id),
                  )
                  .length;
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: const Icon(Icons.collections_bookmark_rounded),
                  title: Text(collection.title),
                  subtitle: Text(
                    '${collection.description}\n'
                    '$added of ${collection.references.length} added',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => AppRouter.push(
                    context,
                    MemoryCollectionDetailScreen(collection: collection),
                    transition: AppTransitionType.slideRight,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
