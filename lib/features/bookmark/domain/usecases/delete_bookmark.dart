import '../repositories/bookmark_repository.dart';

class DeleteBookmark {
  final BookmarkRepository _repository;
  const DeleteBookmark(this._repository);

  Future<void> call(String id) => _repository.delete(id);
}
