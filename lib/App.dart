import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:ikaros/DesktopView.dart';
import 'package:ikaros/MobileView.dart';
import 'package:ikaros/utils/PlatformUtils.dart';
import 'package:system_theme/system_theme.dart';

void main() {
  bool isMobile = PlatformUtils.isMobile();
  runApp(isMobile ?  const MobileApp() : const DesktopApp());
}

class MobileApp extends StatelessWidget {
  const MobileApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ikaros',
      home: MobileView(),
    );
  }
}

class DesktopApp extends StatelessWidget {
  const DesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: "Ikaros Desktop",
      theme: FluentThemeData(
        accentColor: SystemTheme.accentColor.accent.toAccentColor(),
      ),
      home: DesktopView(),
    );
  }

}
