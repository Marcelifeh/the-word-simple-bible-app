import 'package:hive/hive.dart';

import '../model/user_tract.dart';

class UserTractRepository {
  static const _boxName = 'user_tracts';
  Box<UserTract>? _box;

  Future<void> init() async {
    try {
      _box = await Hive.openBox<UserTract>(_boxName);
    } catch (_) {
      try {
        await Hive.deleteBoxFromDisk(_boxName);
      } catch (_) {}
      _box = await Hive.openBox<UserTract>(_boxName);
    }
  }

  List<UserTract> getAll() {
    final values = _box?.values.toList() ?? [];
    // Newest first
    values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  void add(UserTract tract) {
    _box?.put(tract.id, tract);
  }

  void delete(String id) {
    _box?.delete(id);
  }
}
