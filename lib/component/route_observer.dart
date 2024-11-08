import 'package:flutter/cupertino.dart';

class IkarosRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPop(Route route, Route? previousRoute) {
    debugPrint("Route popped form [${previousRoute?.settings}] to [${route.settings}]");
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    debugPrint("Route pushed form [${previousRoute?.settings}] to [${route.settings}]");
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    debugPrint("Route removed form [${previousRoute?.settings}] to [${route.settings}]");
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    debugPrint("Route replaced form [${oldRoute?.settings}] to [${newRoute?.settings}]");
  }
}
