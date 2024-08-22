import 'package:flutter/material.dart';
import 'package:ikaros/layout.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ikaros',
      home: screenWidth > 600 ?  const DesktopLayout(): const MobileLayout(),
    );
  }
}
