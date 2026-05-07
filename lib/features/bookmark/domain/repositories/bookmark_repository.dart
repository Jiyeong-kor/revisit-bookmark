import '../entities/bookmark.dart';

abstract interface class BookmarkRepository {
  Future<List<Bookmark>> getAll();
  Future<void> save(Bookmark bookmark);
  Future<void> delete(String id);
  Future<Bookmark?> getRandom();
}
