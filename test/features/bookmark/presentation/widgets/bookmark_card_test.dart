import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revisit_bookmark/features/bookmark/domain/entities/bookmark.dart';
import 'package:revisit_bookmark/features/bookmark/presentation/widgets/bookmark_card.dart';

Bookmark makeBookmark({
  required BookmarkType type,
  String? url,
  String? thumbnailPath,
  String? content,
}) =>
    Bookmark(
      id: 'test-id',
      type: type,
      status: BookmarkStatus.active,
      title: '테스트 제목',
      description: '테스트 설명',
      url: url,
      thumbnailPath: thumbnailPath,
      content: content,
      createdAt: DateTime(2026),
    );

Widget buildCard(Bookmark bookmark) => MaterialApp(
      home: Scaffold(body: BookmarkCard(bookmark: bookmark)),
    );

void main() {
  group('BookmarkCard 렌더링', () {
    testWidgets('링크 카드는 타입 레이블 "링크"를 표시한다', (tester) async {
      await tester.pumpWidget(
        buildCard(makeBookmark(type: BookmarkType.link, url: 'https://example.com')),
      );
      expect(find.text('링크'), findsOneWidget);
    });

    testWidgets('메모 카드는 타입 레이블 "메모"를 표시한다', (tester) async {
      await tester.pumpWidget(
        buildCard(makeBookmark(type: BookmarkType.memo)),
      );
      expect(find.text('메모'), findsOneWidget);
    });

    testWidgets('스크린샷 카드는 타입 레이블 "스크린샷"을 표시한다', (tester) async {
      await tester.pumpWidget(
        buildCard(makeBookmark(type: BookmarkType.screenshot)),
      );
      expect(find.text('스크린샷'), findsOneWidget);
    });

    testWidgets('제목이 카드에 표시된다', (tester) async {
      await tester.pumpWidget(
        buildCard(makeBookmark(type: BookmarkType.memo)),
      );
      expect(find.text('테스트 제목'), findsOneWidget);
    });
  });

  group('BookmarkCard 썸네일', () {
    testWidgets('thumbnailPath가 null이면 이미지 영역이 없다', (tester) async {
      await tester.pumpWidget(
        buildCard(makeBookmark(type: BookmarkType.link, thumbnailPath: null)),
      );
      expect(find.byType(AspectRatio), findsNothing);
    });
  });
}
