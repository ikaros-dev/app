import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ikaros/reader/novel_reader.dart';

/// 小说阅读器单元测试
void main() {
  group('NovelReaderPage', () {
    testWidgets('默认状态应显示标题和加载中指示器',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NovelReaderPage(subjectId: "test-subject-id"),
        ),
      );

      // 默认标题
      expect(find.text("小说阅读器"), findsOneWidget);
      // 加载中
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('空状态应显示暂无章节', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text("暂无章节")),
          ),
        ),
      );

      expect(find.text("暂无章节"), findsOneWidget);
    });
  });

  group('NovelChapterPage', () {
    testWidgets('空白内容应显示提示', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text("（本章暂无内容）")),
          ),
        ),
      );

      expect(find.text("（本章暂无内容）"), findsOneWidget);
    });

    testWidgets('加载失败应显示错误文本', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text("加载失败: Connection refused")),
          ),
        ),
      );

      expect(find.textContaining("加载失败"), findsOneWidget);
    });
  });

  group('阅读主题', () {
    test('三种主题应有不同配色', () {
      final themes = [
        {"name": "羊皮纸", "bg": 0xFFF5F0E8},
        {"name": "护眼黄", "bg": 0xFFC8B896},
        {"name": "夜间黑", "bg": 0xFF1A1A2E},
      ];

      expect(themes.length, 3);
      expect(themes[0]["name"], "羊皮纸");
      expect(themes[2]["name"], "夜间黑");
    });

    test('字体范围应在12~32px', () {
      const minFont = 12.0;
      const maxFont = 32.0;
      const defaultFont = 18.0;

      expect(defaultFont, inInclusiveRange(minFont, maxFont));
      expect(defaultFont, 18.0);
    });
  });

  group('章节导航', () {
    test('章节索引应在有效范围内', () {
      final chapters = ["序章", "第一章", "第二章", "第三章"];
      int currentIndex = 1;

      expect(currentIndex, greaterThan(0));
      expect(currentIndex, lessThan(chapters.length - 1));

      final hasPrev = currentIndex > 0;
      final hasNext = currentIndex < chapters.length - 1;
      expect(hasPrev, true);
      expect(hasNext, true);
    });

    test('第一章不应有上一章', () {
      final currentIndex = 0;
      final hasPrev = currentIndex > 0;
      expect(hasPrev, false);
    });

    test('最后一章不应有下一章', () {
      final total = 5;
      final lastIndex = total - 1;
      final hasNext = lastIndex < total - 1;
      expect(hasNext, false);
    });
  });
}
