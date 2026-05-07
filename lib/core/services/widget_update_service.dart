import 'dart:convert';
import 'dart:math';

import 'package:home_widget/home_widget.dart';

import '../../features/bookmark/domain/entities/bookmark.dart';
import '../../features/bookmark/domain/repositories/bookmark_repository.dart';

class WidgetUpdateService {
  static const _androidName = 'BookmarkGlanceWidgetReceiver';

  final BookmarkRepository _repository;

  WidgetUpdateService(this._repository);

  Future<void> refresh() async {
    final allActive = await _repository.getAll(status: BookmarkStatus.active);
    final items = _selectItems(allActive, 3);

    if (items.isNotEmpty) {
      await _repository.markAsShown(items.first.id);
    }

    await _writeWidgetData(items);
    await HomeWidget.updateWidget(androidName: _androidName);
  }

  /// lastShownAt 기준 오래된 항목을 우선으로, count*2 후보에서 랜덤 선택
  List<Bookmark> _selectItems(List<Bookmark> bookmarks, int count) {
    if (bookmarks.isEmpty) return [];

    final sorted = [...bookmarks]..sort((a, b) {
        if (a.lastShownAt == null && b.lastShownAt == null) return 0;
        if (a.lastShownAt == null) return -1;
        if (b.lastShownAt == null) return 1;
        return a.lastShownAt!.compareTo(b.lastShownAt!);
      });

    final candidateCount = min(count * 2, sorted.length);
    final candidates = sorted.sublist(0, candidateCount)..shuffle(Random());
    return candidates.take(count).toList();
  }

  Future<void> _writeWidgetData(List<Bookmark> bookmarks) async {
    final items = bookmarks
        .map((b) => {
              'title': b.title,
              'type': b.type.name,
              'description': b.description ?? b.content ?? '',
              'url': b.url ?? '',
              'sourceDomain': b.sourceDomain ?? '',
            })
        .toList();
    await HomeWidget.saveWidgetData<String>('widget_items', jsonEncode(items));
  }
}
