import '../../features/bookmark/domain/entities/bookmark.dart';
import '../../features/bookmark/domain/repositories/bookmark_repository.dart';

/// 앱 최초 실행 시 UI 검토용 샘플 데이터를 삽입한다.
/// 박스가 비어 있을 때만 동작하므로 실제 사용자 데이터를 덮어쓰지 않는다.
class MockDataSeeder {
  static Future<void> seedIfEmpty(BookmarkRepository repository) async {
    final existing = await repository.getAll();
    if (existing.isNotEmpty) return;

    for (final bookmark in _mockBookmarks) {
      await repository.save(bookmark);
    }
  }

  static final _now = DateTime.now();

  static final List<Bookmark> _mockBookmarks = [
    // ── 링크 ───────────────────────────────────────────────
    Bookmark(
      id: 'mock-link-1',
      type: BookmarkType.link,
      status: BookmarkStatus.active,
      title: 'Flutter 3.x에서 달라진 렌더링 엔진 Impeller 정리',
      description:
          'Impeller가 기본 렌더러로 전환되면서 셰이더 지터 문제가 해결됐다. '
          '실제 앱에서 체감할 수 있는 차이와 마이그레이션 주의사항을 정리했다.',
      url: 'https://medium.com/flutter/impeller-flutter-rendering',
      sourceDomain: 'medium.com',
      thumbnailPath:
          'https://picsum.photos/seed/flutter/600/400',
      createdAt: _now.subtract(const Duration(days: 12)),
      lastShownAt: _now.subtract(const Duration(days: 3)),
    ),
    Bookmark(
      id: 'mock-link-2',
      type: BookmarkType.link,
      status: BookmarkStatus.active,
      title: '생산성을 10배 올려준 노션 템플릿 공유',
      description: '프로젝트 관리부터 독서 노트까지, 6개월간 다듬은 나만의 워크스페이스 구조를 공개합니다.',
      url: 'https://www.youtube.com/watch?v=notion-template',
      sourceDomain: 'youtube.com',
      thumbnailPath:
          'https://picsum.photos/seed/notion/600/400',
      createdAt: _now.subtract(const Duration(days: 5)),
    ),
    Bookmark(
      id: 'mock-link-3',
      type: BookmarkType.link,
      status: BookmarkStatus.active,
      title: 'Why Riverpod over Provider in 2025',
      description:
          'A practical comparison of Flutter state management solutions '
          'focusing on testability and maintainability.',
      url: 'https://codewithandrea.com/articles/riverpod-vs-provider',
      sourceDomain: 'codewithandrea.com',
      thumbnailPath:
          'https://picsum.photos/seed/riverpod/600/400',
      createdAt: _now.subtract(const Duration(days: 20)),
      lastShownAt: _now.subtract(const Duration(days: 10)),
    ),
    Bookmark(
      id: 'mock-link-4',
      type: BookmarkType.link,
      status: BookmarkStatus.archived,
      title: '무조건 읽어야 할 UX 법칙 10가지',
      description: '힉의 법칙, 피츠의 법칙 등 실무에 바로 적용 가능한 UX 원칙 정리.',
      url: 'https://lawsofux.com',
      sourceDomain: 'lawsofux.com',
      thumbnailPath:
          'https://picsum.photos/seed/ux/600/400',
      createdAt: _now.subtract(const Duration(days: 30)),
      lastShownAt: _now.subtract(const Duration(days: 15)),
    ),

    // ── 스크린샷 ───────────────────────────────────────────
    Bookmark(
      id: 'mock-screenshot-1',
      type: BookmarkType.screenshot,
      status: BookmarkStatus.active,
      title: '스크린샷 2026-04-21',
      description: '인스타그램에서 저장한 미니멀 인테리어 레퍼런스',
      thumbnailPath:
          'https://picsum.photos/seed/interior/600/400',
      createdAt: _now.subtract(const Duration(days: 8)),
    ),
    Bookmark(
      id: 'mock-screenshot-2',
      type: BookmarkType.screenshot,
      status: BookmarkStatus.active,
      title: '스크린샷 2026-04-28',
      description: '앱 디자인 레퍼런스 — 카드 UI 레이아웃',
      thumbnailPath:
          'https://picsum.photos/seed/appdesign/600/400',
      createdAt: _now.subtract(const Duration(days: 1)),
    ),

    // ── 메모 ───────────────────────────────────────────────
    Bookmark(
      id: 'mock-memo-1',
      type: BookmarkType.memo,
      status: BookmarkStatus.active,
      title: '사이드 프로젝트 아이디어',
      content:
          '사람들이 저장한 정보를 실제로 다시 보지 않는 문제를 해결하는 앱.\n\n'
          '홈 화면 위젯에서 랜덤으로 보여주면 어떨까?\n'
          '북마크 → 재노출 → 실제 소비까지 이어지는 흐름이 핵심.',
      createdAt: _now.subtract(const Duration(days: 45)),
      lastShownAt: _now.subtract(const Duration(days: 2)),
    ),
    Bookmark(
      id: 'mock-memo-2',
      type: BookmarkType.memo,
      status: BookmarkStatus.active,
      title: '읽은 책 - 원씽 (The ONE Thing)',
      content:
          '"지금 당장 할 수 있는 단 한 가지 일은 무엇인가?\n'
          '그것을 함으로써 다른 모든 일이 쉬워지거나 불필요해지는 일."\n\n'
          '멀티태스킹은 생산성의 적이다. 하나에만 집중할 것.',
      createdAt: _now.subtract(const Duration(days: 60)),
    ),
    Bookmark(
      id: 'mock-memo-3',
      type: BookmarkType.memo,
      status: BookmarkStatus.active,
      title: '코드 리뷰에서 받은 피드백',
      content:
          '- Repository 패턴에서 data source는 반드시 추상화할 것\n'
          '- UseCase는 단일 책임 원칙 적용\n'
          '- Provider는 UI 레이어에만 두기\n'
          '- 테스트 작성 시 mock은 최소화',
      createdAt: _now.subtract(const Duration(days: 3)),
    ),
    Bookmark(
      id: 'mock-memo-4',
      type: BookmarkType.memo,
      status: BookmarkStatus.hidden,
      title: '임시 메모 (숨김 처리)',
      content: '나중에 정리할 내용. 지금은 위젯에 안 보이게.',
      createdAt: _now.subtract(const Duration(days: 2)),
    ),
  ];
}
