import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/services/share_intent_service.dart';
import 'core/services/widget_update_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/mock_data_seeder.dart';
import 'features/bookmark/data/datasources/local/hive_bookmark_datasource.dart';
import 'features/bookmark/data/models/bookmark_model.dart';
import 'features/bookmark/data/repositories/bookmark_repository_impl.dart';
import 'features/bookmark/presentation/pages/home_page.dart';
import 'features/bookmark/presentation/pages/share_save_sheet.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(BookmarkModelAdapter());
  final box = await Hive.openBox<BookmarkModel>(kBookmarkBox);

  final repository = BookmarkRepositoryImpl(HiveBookmarkDataSource(box));
  await MockDataSeeder.seedIfEmpty(repository);

  // 앱 시작 시 위젯 데이터 초기화 (앱을 재설치해도 기존 북마크가 위젯에 표시됨)
  unawaited(WidgetUpdateService(repository).refresh());

  runApp(const ProviderScope(child: App()));
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _shareService = ShareIntentService();
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _handleInitialShare();
    _shareService.sharedText.listen(_showShareSheet);
  }

  @override
  void dispose() {
    _shareService.dispose();
    super.dispose();
  }

  Future<void> _handleInitialShare() async {
    final text = await _shareService.getInitialSharedText();
    if (text != null) {
      // 첫 프레임이 렌더링된 뒤 시트를 열어야 context가 준비됨
      WidgetsBinding.instance.addPostFrameCallback((_) => _showShareSheet(text));
    }
  }

  void _showShareSheet(String text) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ShareSaveSheet(sharedText: text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const HomePage(),
    );
  }
}
