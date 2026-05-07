import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/widget_update_service.dart';
import '../../data/datasources/local/hive_bookmark_datasource.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/repositories/bookmark_repository_impl.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../../domain/usecases/delete_bookmark.dart';
import '../../domain/usecases/get_all_bookmarks.dart';
import '../../domain/usecases/get_next_for_widget.dart';
import '../../domain/usecases/save_bookmark.dart';
import '../../domain/usecases/update_bookmark_status.dart';

// --- 인프라 레이어 ---

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  final box = Hive.box<BookmarkModel>(kBookmarkBox);
  final dataSource = HiveBookmarkDataSource(box);
  return BookmarkRepositoryImpl(dataSource);
});

// --- UseCase 레이어 ---

final getAllBookmarksProvider = Provider<GetAllBookmarks>(
  (ref) => GetAllBookmarks(ref.watch(bookmarkRepositoryProvider)),
);

final saveBookmarkProvider = Provider<SaveBookmark>(
  (ref) => SaveBookmark(ref.watch(bookmarkRepositoryProvider)),
);

final deleteBookmarkProvider = Provider<DeleteBookmark>(
  (ref) => DeleteBookmark(ref.watch(bookmarkRepositoryProvider)),
);

final getNextForWidgetProvider = Provider<GetNextForWidget>(
  (ref) => GetNextForWidget(ref.watch(bookmarkRepositoryProvider)),
);

final updateBookmarkStatusProvider = Provider<UpdateBookmarkStatus>(
  (ref) => UpdateBookmarkStatus(ref.watch(bookmarkRepositoryProvider)),
);

// --- 상태 레이어 ---

final widgetUpdateServiceProvider = Provider<WidgetUpdateService>(
  (ref) => WidgetUpdateService(ref.watch(bookmarkRepositoryProvider)),
);

/// 전체 북마크 목록 (active 항목만)
final bookmarkListProvider = FutureProvider<List<Bookmark>>((ref) {
  final useCase = ref.watch(getAllBookmarksProvider);
  return useCase(status: BookmarkStatus.active);
});
