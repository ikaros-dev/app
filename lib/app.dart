import 'package:dart_vlc/dart_vlc.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ikaros/api/collection/model/SubjectCollection.dart';
import 'package:ikaros/mobile_view.dart';
import 'package:ikaros/subject/subject_details_view.dart';
import 'package:ikaros/utils/platform_utils.dart';
import 'package:system_theme/system_theme.dart';
import 'package:ikaros/api/subject/model/Subject.dart';

import 'desktop_view.dart';

void main() {
  bool isMobile = PlatformUtils.isMobile();
  if (!isMobile) DartVLC.initialize();
  runApp(isMobile ? const MobileApp() : const DesktopApp());
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


final _router = GoRouter(
  routes: [
    GoRoute(path: "/", builder: (context, state) => const DesktopView()),
    GoRoute(
      path: '/subject/details',
      builder: (context, state) {
        var json = state.extra as Map<String, dynamic>;
        var apiBaseUrl = json['apiBaseUrl'];
        var subject = json['subject'];
        var collection = json['collection'];
        return SubjectDetailsView(apiBaseUrl: apiBaseUrl, subject: subject, collection: collection);
      },
    )
  ],
);


class DesktopApp extends StatelessWidget {
  const DesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp.router(
      title: "Ikaros Desktop",
      routerConfig: _router,
      theme: FluentThemeData(
        accentColor: SystemTheme.accentColor.accent.toAccentColor(),
      ),
    );
  }

}
