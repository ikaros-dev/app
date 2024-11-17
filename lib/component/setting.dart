import 'package:flutter/material.dart';

class Setting extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? rightWidget;

  const Setting({super.key, required this.title, required this.subtitle, this.rightWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧包含标题和副标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题部分，字体加重
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // 副标题部分，较小的字体
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          // 右侧控件，如大文本或开关
          rightWidget ?? Container(),
        ],
      ),
    );
  }

}