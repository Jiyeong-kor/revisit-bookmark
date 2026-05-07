import '../entities/bookmark.dart';
import '../repositories/bookmark_repository.dart';

class UpdateBookmarkStatus {
  final BookmarkRepository _repository;
  const UpdateBookmarkStatus(this._repository);

  Future<void> call(String id, BookmarkStatus status) =>
      _repository.updateStatus(id, status);
}
