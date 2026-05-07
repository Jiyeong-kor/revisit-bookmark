import 'package:hive_flutter/hive_flutter.dart';

import '../../models/bookmark_model.dart';

class HiveBookmarkDataSource {
  final Box<BookmarkModel> _box;

  const HiveBookmarkDataSource(this._box);

  List<BookmarkModel> getAll({int? statusIndex}) {
    final values = _box.values;
    if (statusIndex == null) return values.toList();
    return values.where((m) => m.status == statusIndex).toList();
  }

  BookmarkModel? getById(String id) => _box.get(id);

  Future<void> save(BookmarkModel model) => _box.put(model.id, model);

  Future<void> delete(String id) => _box.delete(id);

  Future<void> updateLastShownAt(String id, DateTime shownAt) async {
    final model = _box.get(id);
    if (model == null) return;
    await _box.put(
      id,
      model.copyWith(lastShownAtMs: shownAt.millisecondsSinceEpoch),
    );
  }

  Future<void> updateStatus(String id, int statusIndex) async {
    final model = _box.get(id);
    if (model == null) return;
    await _box.put(id, model.copyWith(status: statusIndex));
  }
}
