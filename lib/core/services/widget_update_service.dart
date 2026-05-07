import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../features/bookmark/domain/entities/bookmark.dart';
import '../../features/bookmark/domain/repositories/bookmark_repository.dart';

class WidgetUpdateService {
  static const _androidName = 'BookmarkGlanceWidgetReceiver';

  final BookmarkRepository _repository;

  WidgetUpdateService(this._repository);

  Future<void> refresh() async {
    final allActive = await _repository.getAll(status: BookmarkStatus.active);
    final items = _selectItems(allActive, 4);

    if (items.isNotEmpty) {
      await _repository.markAsShown(items.first.id);
    }

    await _writeWidgetData(items);
    await HomeWidget.updateWidget(androidName: _androidName);
  }

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
    // 링크 OG 이미지: 첫 번째 링크 아이템만 다운로드
    final firstLink = bookmarks.where((b) => b.type == BookmarkType.link).firstOrNull;
    final firstLinkThumbnail =
        firstLink != null ? await _resolveRemoteThumbnail(firstLink) : null;

    final items = <Map<String, String>>[];
    for (final b in bookmarks) {
      final thumbnailLocalPath = switch (b.type) {
        // 스크린샷: 로컬 경로 직접 사용 (모든 아이템)
        BookmarkType.screenshot => b.thumbnailPath ?? '',
        // 링크: 첫 번째 아이템만 OG 이미지
        BookmarkType.link =>
          (b == firstLink) ? (firstLinkThumbnail ?? '') : '',
        // 메모: 이미지 없음
        BookmarkType.memo => '',
      };

      items.add({
        'title': b.title,
        'type': b.type.name,
        // 메모는 전체 본문, 링크는 OG description
        'description': b.type == BookmarkType.memo
            ? (b.content ?? b.description ?? '')
            : (b.description ?? ''),
        'url': b.url ?? '',
        'sourceDomain': b.sourceDomain ?? '',
        'thumbnailLocalPath': thumbnailLocalPath,
      });
    }

    await HomeWidget.saveWidgetData<String>('widget_items', jsonEncode(items));
  }

  /// 링크 OG 이미지(URL)를 로컬에 다운로드 후 경로 반환.
  /// 이미 로컬 경로면 그대로 반환.
  Future<String?> _resolveRemoteThumbnail(Bookmark bookmark) async {
    final path = bookmark.thumbnailPath;
    if (path == null || path.isEmpty) return null;
    if (!path.startsWith('http')) return path;

    try {
      final response = await http
          .get(Uri.parse(path))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/widget_thumb.jpg');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
