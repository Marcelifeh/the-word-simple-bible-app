import 'dart:convert';

import 'package:flutter/services.dart';

import '../model/memory_collection.dart';

class MemoryCollectionRepository {
  MemoryCollectionRepository({AssetBundle? assetBundle})
      : _assetBundle = assetBundle ?? rootBundle;

  static const assetPaths = <String>[
    'assets/data/scripture_memory/collections/foundations_of_faith.json',
    'assets/data/scripture_memory/collections/peace_in_anxiety.json',
    'assets/data/scripture_memory/collections/prayer_and_trust.json',
    'assets/data/scripture_memory/collections/identity_in_christ.json',
    'assets/data/scripture_memory/collections/salvation_and_grace.json',
  ];

  final AssetBundle _assetBundle;
  List<MemoryCollection>? _cache;

  Future<List<MemoryCollection>> loadCollections() async {
    if (_cache != null) return _cache!;
    final collections = <MemoryCollection>[];
    for (final path in assetPaths) {
      final raw = await _assetBundle.loadString(path);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw FormatException('Invalid collection asset: $path');
      }
      collections.add(
        MemoryCollection.fromJson(Map<String, dynamic>.from(decoded)),
      );
    }
    _cache = List<MemoryCollection>.unmodifiable(collections);
    return _cache!;
  }
}
