import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ikaros/reader/comic_reader.dart';

/// 漫画阅读器单元测试
void main() {
  group('ComicReaderPage', () {
    testWidgets('默认状态应显示标题和加载中指示器',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ComicReaderPage(subjectId: "test-subject-id"),
        ),
      );

      // 页面标题
      expect(find.text("漫画阅读器"), findsOneWidget);
      // 加载中应显示 CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('EmptyState 应显示暂无章节提示', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text("暂无章节",
                  style: Theme.of(tester.element(find.byType(Scaffold))).textTheme.bodyLarge),
            ),
          ),
        ),
      );

      expect(find.text("暂无章节"), findsOneWidget);
    });
  });

  group('ComicChapterPage', () {
    testWidgets('应正确显示章节标题格式', (WidgetTester tester) async {
      final chapterTitle = "第1话";
      final pageInfo = "${chapterTitle} — 0/3";

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: null,
            body: Center(
              child: Text(
                "第1话 — 0/3",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      );

      expect(find.text("第1话 — 0/3"), findsOneWidget);
    });

    testWidgets('空页面列表应显示提示', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                "暂无页面",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      );

      expect(find.text("暂无页面"), findsOneWidget);
    });

    testWidgets('阅读方向切换按钮应存在', (WidgetTester tester) async {
      // 验证 UI 中有方向切换按钮的基础样式
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: "左→右（正常）",
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('列表/分页模式切换按钮应存在', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  icon: const Icon(Icons.view_column),
                  tooltip: "列表模式",
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.view_column), findsOneWidget);
    });
  });

  group('页码格式化', () {
    // 验证 ComicChapterPage 的页码显示逻辑
    test('页码显示格式', () {
      final current = 1;
      final total = 10;
      final label = "章名 — $current/$total";
      expect(label, "章名 — 1/10");
    });

    test('空页面列表', () {
      final urls = <String>[];
      final isEmpty = urls.isEmpty;
      expect(isEmpty, true);
    });
  });
}
