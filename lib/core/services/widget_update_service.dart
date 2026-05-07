import 'package:home_widget/home_widget.dart';

import '../../features/bookmark/domain/entities/bookmark.dart';
import '../../features/bookmark/domain/repositories/bookmark_repository.dart';
import '../../features/bookmark/domain/usecases/get_next_for_widget.dart';

class WidgetUpdateService {
  static const _androidName = 'BookmarkGlanceWidgetReceiver';

  final BookmarkRepository _repository;
  late final GetNextForWidget _getNext;

  WidgetUpdateService(this._repository) {
    _getNext = GetNextForWidget(_repository);
  }

  Future<void> refresh() async {
    final bookmark = await _getNext();
    if (bookmark != null) {
      await _repository.markAsShown(bookmark.id);
    }
    await _writeWidgetData(bookmark);
    await HomeWidget.updateWidget(androidName: _androidName);
  }

  Future<void> _writeWidgetData(Bookmark? bookmark) async {
    await HomeWidget.saveWidgetData<String>('widget_title', bookmark?.title ?? '');
    await HomeWidget.saveWidgetData<String>('widget_type', bookmark?.type.name ?? '');
    await HomeWidget.saveWidgetData<String>(
      'widget_description',
      bookmark?.description ?? bookmark?.content ?? '',
    );
    await HomeWidget.saveWidgetData<String>(
      'widget_source_domain',
      bookmark?.sourceDomain ?? '',
    );
  }
}
