import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/bookmark.dart';
import '../providers/bookmark_providers.dart';

class MemoSaveSheet extends ConsumerStatefulWidget {
  const MemoSaveSheet({super.key});

  @override
  ConsumerState<MemoSaveSheet> createState() => _MemoSaveSheetState();
}

class _MemoSaveSheetState extends ConsumerState<MemoSaveSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) return;

    setState(() => _isSaving = true);

    final bookmark = Bookmark(
      id: const Uuid().v4(),
      type: BookmarkType.memo,
      status: BookmarkStatus.active,
      title: title,
      content: content,
      createdAt: DateTime.now(),
    );

    await ref.read(saveBookmarkProvider).call(bookmark);
    ref.invalidate(bookmarkListProvider);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !_isSaving;

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
            Text(
              '메모 저장',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '제목',
                prefixIcon: const Icon(Icons.title_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              textInputAction: TextInputAction.newline,
              maxLines: 6,
              minLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '내용을 입력하세요',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: canSave &&
                      _titleController.text.trim().isNotEmpty &&
                      _contentController.text.trim().isNotEmpty
                  ? _save
                  : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('저장', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
