import '../entities/bookmark.dart';

abstract interface class BookmarkRepository {
  /// 전체 북마크 조회 (상태 필터 선택)
  Future<List<Bookmark>> getAll({BookmarkStatus? status});

  /// 단건 조회
  Future<Bookmark?> getById(String id);

  /// 저장 (insert or update)
  Future<void> save(Bookmark bookmark);

  /// 삭제
  Future<void> delete(String id);

  /// 위젯용 랜덤 노출 — active 항목 중 lastShownAt 가중치 적용
  Future<Bookmark?> getNextForWidget();

  /// 위젯 노출 후 lastShownAt 갱신
  Future<void> markAsShown(String id);

  /// 상태 변경 (active / hidden / archived)
  Future<void> updateStatus(String id, BookmarkStatus status);
}
