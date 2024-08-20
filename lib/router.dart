import 'package:go_router/go_router.dart';
import 'package:ikaros/subject/episode.dart';
import 'package:ikaros/subject/subject.dart';
import 'package:ikaros/user/login.dart';

import 'home.dart';

// GoRouter configuration
final router = GoRouter(
  routes: [
    // home
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    // login
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginView(),
    ),
    // subject details
    GoRoute(
      path: "/subject/details/:id",
      builder: (context, state) =>
          SubjectPage(id: state.pathParameters['id']),
    ),
    // subject details
    GoRoute(
      path: "/subject/episode/:id",
      builder: (context, state) =>
          SubjectEpisodePage(id: state.pathParameters['id']),
    ),
  ],
);
