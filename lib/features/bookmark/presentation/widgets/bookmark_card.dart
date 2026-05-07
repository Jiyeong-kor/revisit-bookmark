import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/bookmark.dart';

class BookmarkCard extends StatelessWidget {
  final Bookmark bookmark;

  const BookmarkCard({super.key, required this.bookmark});

  Future<void> _handleTap(BuildContext context) async {
    switch (bookmark.type) {
      case BookmarkType.link:
        final url = bookmark.url;
        if (url == null || url.isEmpty) return;
        final uri = Uri.tryParse(url);
        if (uri == null) return;
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('링크를 열 수 없습니다')),
            );
          }
        }
      case BookmarkType.screenshot:
        final path = bookmark.thumbnailPath;
        if (path == null || path.isEmpty) return;
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _FullScreenImagePage(path: path),
          ),
        );
      case BookmarkType.memo:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: bookmark.type != BookmarkType.memo
            ? () => _handleTap(context)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bookmark.thumbnailPath != null)
              _Thumbnail(url: bookmark.thumbnailPath!),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TypeChip(type: bookmark.type),
                  const SizedBox(height: 8),
                  Text(
                    bookmark.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (bookmark.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      bookmark.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (bookmark.content != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      bookmark.content!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (bookmark.sourceDomain != null) ...[
                    const SizedBox(height: 10),
                    _SourceDomain(domain: bookmark.sourceDomain!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenImagePage extends StatelessWidget {
  final String path;

  const _FullScreenImagePage({required this.path});

  bool get _isLocalPath =>
      path.startsWith('/') || path.startsWith('file://');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: _isLocalPath
              ? Image.file(File(path), fit: BoxFit.contain)
              : Image.network(path, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String url;

  const _Thumbnail({required this.url});

  bool get _isLocalPath => url.startsWith('/') || url.startsWith('file://');

  @override
  Widget build(BuildContext context) {
    final errorWidget = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.broken_image_outlined,
        color: Theme.of(context).colorScheme.outline,
      ),
    );

    if (_isLocalPath) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.file(
          File(url),
          fit: BoxFit.cover,
          errorBuilder: (context, e, stack) => errorWidget,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, e, stack) => errorWidget,
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          );
        },
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final BookmarkType type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (type) {
      BookmarkType.link => (Icons.link_rounded, '링크'),
      BookmarkType.screenshot => (Icons.image_outlined, '스크린샷'),
      BookmarkType.memo => (Icons.edit_note_rounded, '메모'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _SourceDomain extends StatelessWidget {
  final String domain;

  const _SourceDomain({required this.domain});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.language_rounded,
          size: 12,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Text(
          domain,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }
}
