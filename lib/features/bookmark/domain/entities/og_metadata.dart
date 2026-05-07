class OgMetadata {
  final String? title;
  final String? description;
  final String? imageUrl;
  final String sourceDomain;

  const OgMetadata({
    this.title,
    this.description,
    this.imageUrl,
    required this.sourceDomain,
  });
}
