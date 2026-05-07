import 'package:flutter_test/flutter_test.dart';
import 'package:revisit_bookmark/core/services/widget_update_service.dart';
import 'package:revisit_bookmark/features/bookmark/domain/entities/bookmark.dart';
import 'package:revisit_bookmark/features/bookmark/domain/repositories/bookmark_repository.dart';

// ── Fake Repository ─────────────────────────────────────────────────────────

class FakeBookmarkRepository implements BookmarkRepository {
  final List<Bookmark> bookmarks;
  FakeBookmarkRepository(this.bookmarks);

  @override
  Future<List<Bookmark>> getAll({BookmarkStatus? status}) async {
    if (status == null) return bookmarks;
    return bookmarks.where((b) => b.status == status).toList();
  }

  @override
  Future<void> markAsShown(String id) async {}

  @override
  Future<Bookmark?> getById(String id) async => null;

  @override
  Future<void> save(Bookmark bookmark) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<Bookmark?> getNextForWidget() async => null;

  @override
  Future<void> updateStatus(String id, BookmarkStatus status) async {}
}

// ── 테스트용 Bookmark 생성 헬퍼 ────────────────────────────────────────────

Bookmark makeLink({
  String id = 'link-1',
  String? thumbnailPath,
  String? url,
  String? description,
}) =>
    Bookmark(
      id: id,
      type: BookmarkType.link,
      status: BookmarkStatus.active,
      title: '링크 제목',
      description: description,
      thumbnailPath: thumbnailPath,
      url: url ?? 'https://example.com',
      sourceDomain: 'example.com',
      createdAt: DateTime(2026),
    );

Bookmark makeScreenshot({
  String id = 'ss-1',
  String? thumbnailPath,
}) =>
    Bookmark(
      id: id,
      type: BookmarkType.screenshot,
      status: BookmarkStatus.active,
      title: '스크린샷 제목',
      thumbnailPath: thumbnailPath,
      createdAt: DateTime(2026),
    );

Bookmark makeMemo({
  String id = 'memo-1',
  String? content,
  String? description,
}) =>
    Bookmark(
      id: id,
      type: BookmarkType.memo,
      status: BookmarkStatus.active,
      title: '메모 제목',
      content: content,
      description: description,
      createdAt: DateTime(2026),
    );

// ── 테스트 ──────────────────────────────────────────────────────────────────

void main() {
  // ── isLocalPath ────────────────────────────────────────────────────────────

  group('isLocalPath', () {
    test('로컬 파일 경로는 true', () {
      expect(
        WidgetUpdateService.isLocalPath('/data/user/0/com.example/files/img.jpg'),
        isTrue,
      );
    });

    test('http URL은 false', () {
      expect(
        WidgetUpdateService.isLocalPath('https://picsum.photos/seed/test/600/400'),
        isFalse,
      );
      expect(
        WidgetUpdateService.isLocalPath('http://example.com/img.jpg'),
        isFalse,
      );
    });

    test('null 또는 빈 문자열은 false', () {
      expect(WidgetUpdateService.isLocalPath(null), isFalse);
      expect(WidgetUpdateService.isLocalPath(''), isFalse);
    });
  });

  // ── thumbnailPathFor ───────────────────────────────────────────────────────

  group('thumbnailPathFor', () {
    test('스크린샷: 로컬 경로는 그대로 반환', () {
      const localPath = '/data/user/0/com.example/files/screenshot.jpg';
      final b = makeScreenshot(thumbnailPath: localPath);
      expect(WidgetUpdateService.thumbnailPathFor(b, null, null), localPath);
    });

    test('스크린샷: HTTP URL은 빈 문자열 반환 (BitmapFactory 오류 방지)', () {
      final b =
          makeScreenshot(thumbnailPath: 'https://picsum.photos/seed/test/600/400');
      expect(WidgetUpdateService.thumbnailPathFor(b, null, null), '');
    });

    test('스크린샷: thumbnailPath가 null이면 빈 문자열', () {
      final b = makeScreenshot(thumbnailPath: null);
      expect(WidgetUpdateService.thumbnailPathFor(b, null, null), '');
    });

    test('링크: 첫 번째 링크 아이템은 resolvedThumbnail 사용', () {
      final b = makeLink(id: 'link-1');
      const resolved = '/local/widget_thumb.jpg';
      expect(WidgetUpdateService.thumbnailPathFor(b, b, resolved), resolved);
    });

    test('링크: 두 번째 이후 링크 아이템은 빈 문자열', () {
      final first = makeLink(id: 'link-1');
      final second = makeLink(id: 'link-2');
      expect(
        WidgetUpdateService.thumbnailPathFor(second, first, '/local/thumb.jpg'),
        '',
      );
    });

    test('링크: resolvedThumbnail이 null이면 빈 문자열', () {
      final b = makeLink(id: 'link-1');
      expect(WidgetUpdateService.thumbnailPathFor(b, b, null), '');
    });

    test('메모: 항상 빈 문자열', () {
      final b = makeMemo();
      expect(WidgetUpdateService.thumbnailPathFor(b, null, null), '');
    });
  });

  // ── buildItems ─────────────────────────────────────────────────────────────

  group('buildItems', () {
    late WidgetUpdateService service;

    setUp(() {
      service = WidgetUpdateService(FakeBookmarkRepository([]));
    });

    test('스크린샷 HTTP URL이 thumbnailLocalPath에 저장되지 않는다', () async {
      final items = await service.buildItems(
        [makeScreenshot(thumbnailPath: 'https://picsum.photos/seed/test/600/400')],
        resolver: (_) async => null,
      );
      expect(items.first['thumbnailLocalPath'], '');
    });

    test('스크린샷 로컬 경로는 thumbnailLocalPath에 저장된다', () async {
      const localPath = '/data/user/0/app/files/screenshot.jpg';
      final items = await service.buildItems(
        [makeScreenshot(thumbnailPath: localPath)],
        resolver: (_) async => null,
      );
      expect(items.first['thumbnailLocalPath'], localPath);
    });

    test('메모는 content 전체를 description 필드에 저장한다', () async {
      const fullContent = '첫 줄\n두 번째 줄\n세 번째 줄';
      final items = await service.buildItems(
        [makeMemo(content: fullContent)],
        resolver: (_) async => null,
      );
      expect(items.first['description'], fullContent);
    });

    test('메모에 content가 없으면 description 필드를 사용한다', () async {
      final items = await service.buildItems(
        [makeMemo(content: null, description: '요약')],
        resolver: (_) async => null,
      );
      expect(items.first['description'], '요약');
    });

    test('링크 OG 이미지: 첫 번째 링크만 resolver로 경로를 가져온다', () async {
      const resolvedPath = '/local/widget_thumb.jpg';
      final link1 = makeLink(id: 'link-1', thumbnailPath: 'https://og.com/1.jpg');
      final link2 = makeLink(id: 'link-2', thumbnailPath: 'https://og.com/2.jpg');

      final items = await service.buildItems(
        [link1, link2],
        resolver: (b) async => b.id == 'link-1' ? resolvedPath : null,
      );

      expect(items[0]['thumbnailLocalPath'], resolvedPath);
      expect(items[1]['thumbnailLocalPath'], '');
    });

    test('아이템 수만큼 결과가 생성된다', () async {
      final bookmarks = [
        makeLink(id: 'l1'),
        makeScreenshot(id: 's1'),
        makeMemo(id: 'm1'),
      ];
      final items = await service.buildItems(
        bookmarks,
        resolver: (_) async => null,
      );
      expect(items.length, 3);
    });

    test('각 아이템에 필수 필드가 모두 포함된다', () async {
      final items = await service.buildItems(
        [makeLink()],
        resolver: (_) async => null,
      );
      final item = items.first;
      expect(item.containsKey('title'), isTrue);
      expect(item.containsKey('type'), isTrue);
      expect(item.containsKey('description'), isTrue);
      expect(item.containsKey('url'), isTrue);
      expect(item.containsKey('sourceDomain'), isTrue);
      expect(item.containsKey('thumbnailLocalPath'), isTrue);
    });
  });
}
