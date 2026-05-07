import '../entities/bookmark.dart';
import '../repositories/bookmark_repository.dart';

class GetAllBookmarks {
  final BookmarkRepository _repository;
  const GetAllBookmarks(this._repository);

  Future<List<Bookmark>> call({BookmarkStatus? status}) =>
      _repository.getAll(status: status);
}
