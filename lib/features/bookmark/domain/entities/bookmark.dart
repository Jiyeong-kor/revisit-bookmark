enum BookmarkType { link, screenshot, memo }

class Bookmark {
  final String id;
  final BookmarkType type;
  final String title;
  final String? description;
  final String? thumbnailPath;
  final String? url;
  final String? filePath;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.thumbnailPath,
    this.url,
    this.filePath,
    required this.createdAt,
  });
}
