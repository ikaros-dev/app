import 'package:flutter/material.dart';
import 'package:ikaros/layout.dart';
import 'package:ikaros/utils/screen_utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // navigatorObservers: [IkarosRouteObserver()],
      debugShowCheckedModeBanner: false,
      title: 'Ikaros',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: ScreenUtils.screenWidthGt600(context)
          ? const DesktopLayout()
          : const MobileLayout(),
    );
  }
}
