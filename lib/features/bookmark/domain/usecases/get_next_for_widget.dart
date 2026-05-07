import '../entities/bookmark.dart';
import '../repositories/bookmark_repository.dart';

/// 홈 화면 위젯에서 다음에 표시할 북마크를 가져온다.
/// active 상태 항목 중 lastShownAt이 가장 오래된 항목을 우선 반환.
class GetNextForWidget {
  final BookmarkRepository _repository;
  const GetNextForWidget(this._repository);

  Future<Bookmark?> call() => _repository.getNextForWidget();
}
