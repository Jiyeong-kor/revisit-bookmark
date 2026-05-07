import 'dart:math';

import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../datasources/local/hive_bookmark_datasource.dart';
import '../models/bookmark_model.dart';

class BookmarkRepositoryImpl implements BookmarkRepository {
  final HiveBookmarkDataSource _dataSource;

  const BookmarkRepositoryImpl(this._dataSource);

  @override
  Future<List<Bookmark>> getAll({BookmarkStatus? status}) async =>
      _dataSource
          .getAll(statusIndex: status?.index)
          .map((m) => m.toEntity())
          .toList();

  @override
  Future<Bookmark?> getById(String id) async =>
      _dataSource.getById(id)?.toEntity();

  @override
  Future<void> save(Bookmark bookmark) =>
      _dataSource.save(BookmarkModel.fromEntity(bookmark));

  @override
  Future<void> delete(String id) => _dataSource.delete(id);

  @override
  Future<void> updateStatus(String id, BookmarkStatus status) =>
      _dataSource.updateStatus(id, status.index);

  @override
  Future<void> markAsShown(String id) =>
      _dataSource.updateLastShownAt(id, DateTime.now());

  /// active 항목 중 lastShownAt이 null(미노출)이거나 가장 오래된 항목을 우선으로,
  /// 상위 3개 후보 중 랜덤 선택하여 단조로움 방지.
  @override
  Future<Bookmark?> getNextForWidget() async {
    final actives = _dataSource.getAll(
      statusIndex: BookmarkStatus.active.index,
    );

    if (actives.isEmpty) return null;

    actives.sort((a, b) {
      if (a.lastShownAtMs == null && b.lastShownAtMs == null) return 0;
      if (a.lastShownAtMs == null) return -1;
      if (b.lastShownAtMs == null) return 1;
      return a.lastShownAtMs!.compareTo(b.lastShownAtMs!);
    });

    final candidateCount = min(3, actives.length);
    final candidates = actives.sublist(0, candidateCount);
    candidates.shuffle(Random());

    return candidates.first.toEntity();
  }
}
