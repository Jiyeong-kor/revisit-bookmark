import '../entities/bookmark.dart';
import '../repositories/bookmark_repository.dart';

class SaveBookmark {
  final BookmarkRepository _repository;
  const SaveBookmark(this._repository);

  Future<void> call(Bookmark bookmark) => _repository.save(bookmark);
}
