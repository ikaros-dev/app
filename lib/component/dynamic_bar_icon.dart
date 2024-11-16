import 'dart:math';
import 'package:flutter/material.dart';

class DynamicBarIcon extends StatefulWidget {
  @override
  _DynamicBarIconState createState() => _DynamicBarIconState();
}

class _DynamicBarIconState extends State<DynamicBarIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();

    // 初始化 AnimationController，控制动画的时间和曲线
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500), // 设置动画持续时间
      vsync: this,
    )..repeat(reverse: true); // 往返重复动画

    // 生成每个柱子的动画，并设置反向动画
    _barAnimations = List.generate(3, (index) {
      // 中间柱子和两边柱子的动画设置
      if (index == 1) {
        // 中间柱子的高度从0.2到1.0
        return Tween<double>(begin: 0.2, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
      } else {
        // 两边柱子高度和中间柱子反向变化
        return Tween<double>(begin: 1.0, end: 0.2).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
      }
    });

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24, // 图标的宽度，与常见图标大小一致
      height: 24, // 图标的高度，与常见图标大小一致
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _BarPainter(_barAnimations),
          );
        },
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<Animation<double>> barAnimations;

  _BarPainter(this.barAnimations);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    double barWidth = size.width / barAnimations.length; // 控制柱子宽度
    double maxHeight = size.height;

    // 绘制三条柱子，使用动画值来控制高度
    for (int i = 0; i < barAnimations.length; i++) {
      double height = barAnimations[i].value * maxHeight;
      double left = i * barWidth;
      double top = maxHeight - height;
      canvas.drawRect(Rect.fromLTWH(left, top, barWidth - 2, height), paint); // 绘制矩形柱子
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // 每次动画更新时都需要重绘
  }
}
