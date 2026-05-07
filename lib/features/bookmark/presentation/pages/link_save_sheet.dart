import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'dart:async';

import '../../data/services/og_metadata_service.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/og_metadata.dart';
import '../providers/bookmark_providers.dart';

// ── 상태 ──────────────────────────────────────────────────────────────

sealed class _LinkSaveState {}

class _Idle extends _LinkSaveState {}

class _Loading extends _LinkSaveState {}

class _Preview extends _LinkSaveState {
  final OgMetadata metadata;
  final String url;
  _Preview({required this.metadata, required this.url});
}

class _Error extends _LinkSaveState {
  final String message;
  _Error(this.message);
}

// ── 바텀시트 ───────────────────────────────────────────────────────────

class LinkSaveSheet extends ConsumerStatefulWidget {
  const LinkSaveSheet({super.key});

  @override
  ConsumerState<LinkSaveSheet> createState() => _LinkSaveSheetState();
}

class _LinkSaveSheetState extends ConsumerState<LinkSaveSheet> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _ogService = OgMetadataService();
  _LinkSaveState _state = _Idle();

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _fetchOg() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _state = _Loading());

    final metadata = await _ogService.fetch(url);

    setState(() {
      _state = _Preview(metadata: metadata, url: url);
      _titleController.text = metadata.title ?? url;
    });
  }

  Future<void> _save() async {
    final state = _state;
    if (state is! _Preview) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final bookmark = Bookmark(
      id: const Uuid().v4(),
      type: BookmarkType.link,
      status: BookmarkStatus.active,
      title: title,
      description: state.metadata.description,
      thumbnailPath: state.metadata.imageUrl,
      url: state.url,
      sourceDomain: state.metadata.sourceDomain,
      createdAt: DateTime.now(),
    );

    await ref.read(saveBookmarkProvider).call(bookmark);
    ref.invalidate(bookmarkListProvider);
    unawaited(ref.read(widgetUpdateServiceProvider).refresh());

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _state is _Loading;
    final hasPreview = _state is _Preview;
    final preview = _state is _Preview ? _state as _Preview : null;

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
            // 드래그 핸들
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
            Text(
              '링크 저장',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),

            // URL 입력
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _fetchOg(),
              decoration: InputDecoration(
                hintText: 'URL을 입력하세요',
                prefixIcon: const Icon(Icons.link_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search_rounded),
                        onPressed: _fetchOg,
                        tooltip: '메타데이터 가져오기',
                      ),
              ),
            ),

            // 에러 메시지
            if (_state is _Error) ...[
              const SizedBox(height: 8),
              Text(
                (_state as _Error).message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],

            // 미리보기 카드
            if (hasPreview && preview != null) ...[
              const SizedBox(height: 20),
              _PreviewCard(
                metadata: preview.metadata,
                titleController: _titleController,
              ),
            ],

            const SizedBox(height: 24),

            // 저장 버튼
            FilledButton(
              onPressed: hasPreview && !isLoading ? _save : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('저장', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 미리보기 카드 ──────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final OgMetadata metadata;
  final TextEditingController titleController;

  const _PreviewCard({
    required this.metadata,
    required this.titleController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metadata.imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                metadata.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목 편집 가능
                TextField(
                  controller: titleController,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: '제목을 입력하세요',
                  ),
                  maxLines: 2,
                ),
                if (metadata.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    metadata.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.language_rounded,
                      size: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      metadata.sourceDomain,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
