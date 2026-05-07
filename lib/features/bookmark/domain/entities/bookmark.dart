enum BookmarkType { link, screenshot, memo }

/// 위젯 노출 정책과 연동되는 상태값.
/// - active: 위젯 랜덤 노출 대상
/// - hidden: 목록에서도, 위젯에서도 노출 안 함
/// - archived: 목록에는 있지만 위젯 노출 제외
enum BookmarkStatus { active, hidden, archived }

class Bookmark {
  final String id;
  final BookmarkType type;
  final BookmarkStatus status;

  /// 링크/스크린샷/메모 모두에서 카드 타이틀로 사용
  final String title;

  /// 링크: OG description / 메모: 본문 첫 줄 요약
  final String? description;

  /// 링크: OG image URL 또는 로컬 캐시 경로 / 스크린샷: 로컬 파일 경로
  final String? thumbnailPath;

  /// link 타입 전용
  final String? url;

  /// 링크 카드 출처 표시용 (예: "youtube.com", "twitter.com")
  final String? sourceDomain;

  /// screenshot 타입 전용 — 로컬 파일 경로
  final String? filePath;

  /// memo 타입 전용 — 전체 본문
  final String? content;

  final DateTime createdAt;

  /// 위젯에서 마지막으로 노출된 시각 — 연속 노출 방지에 사용
  final DateTime? lastShownAt;

  const Bookmark({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    this.description,
    this.thumbnailPath,
    this.url,
    this.sourceDomain,
    this.filePath,
    this.content,
    required this.createdAt,
    this.lastShownAt,
  });

  Bookmark copyWith({
    String? id,
    BookmarkType? type,
    BookmarkStatus? status,
    String? title,
    String? description,
    String? thumbnailPath,
    String? url,
    String? sourceDomain,
    String? filePath,
    String? content,
    DateTime? createdAt,
    DateTime? lastShownAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      url: url ?? this.url,
      sourceDomain: sourceDomain ?? this.sourceDomain,
      filePath: filePath ?? this.filePath,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      lastShownAt: lastShownAt ?? this.lastShownAt,
    );
  }
}
