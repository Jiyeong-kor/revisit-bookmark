import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/services/og_metadata_service.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/og_metadata.dart';
import '../providers/bookmark_providers.dart';

/// 외부 공유로 진입했을 때 표시되는 빠른 저장 시트.
/// URL이면 OG fetch 후 링크로, 그 외 텍스트는 메모로 저장합니다.
class ShareSaveSheet extends ConsumerStatefulWidget {
  final String sharedText;

  const ShareSaveSheet({super.key, required this.sharedText});

  @override
  ConsumerState<ShareSaveSheet> createState() => _ShareSaveSheetState();
}

class _ShareSaveSheetState extends ConsumerState<ShareSaveSheet> {
  final _titleController = TextEditingController();
  final _ogService = OgMetadataService();

  bool _isUrl = false;
  bool _isLoading = true;
  OgMetadata? _metadata;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final text = widget.sharedText.trim();
    final looksLikeUrl = _looksLikeUrl(text);

    if (looksLikeUrl) {
      final metadata = await _ogService.fetch(text);
      if (mounted) {
        setState(() {
          _isUrl = true;
          _metadata = metadata;
          _titleController.text = metadata.title ?? text;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isUrl = false;
          _titleController.text = text.length > 50 ? '${text.substring(0, 50)}...' : text;
          _isLoading = false;
        });
      }
    }
  }

  bool _looksLikeUrl(String text) {
    return text.startsWith('http://') ||
        text.startsWith('https://') ||
        RegExp(r'^[\w-]+(\.[\w-]+)+(/\S*)?$').hasMatch(text);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final Bookmark bookmark;
    if (_isUrl) {
      final meta = _metadata!;
      bookmark = Bookmark(
        id: const Uuid().v4(),
        type: BookmarkType.link,
        status: BookmarkStatus.active,
        title: title,
        description: meta.description,
        thumbnailPath: meta.imageUrl,
        url: widget.sharedText.trim(),
        sourceDomain: meta.sourceDomain,
        createdAt: DateTime.now(),
      );
    } else {
      bookmark = Bookmark(
        id: const Uuid().v4(),
        type: BookmarkType.memo,
        status: BookmarkStatus.active,
        title: title,
        content: widget.sharedText.trim(),
        createdAt: DateTime.now(),
      );
    }

    await ref.read(saveBookmarkProvider).call(bookmark);
    ref.invalidate(bookmarkListProvider);
    unawaited(ref.read(widgetUpdateServiceProvider).refresh());

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  _isUrl ? Icons.link_rounded : Icons.edit_note_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _isUrl ? '링크 저장' : '메모 저장',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // 공유 원문 표시
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.sharedText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              // OG 썸네일 (URL인 경우)
              if (_isUrl && _metadata?.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      _metadata!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // 제목 편집
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: '제목',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
                minLines: 1,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _titleController.text.trim().isNotEmpty ? _save : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('저장', style: TextStyle(fontSize: 16)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
