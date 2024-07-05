import 'package:go_router/go_router.dart';
import 'package:template/core/helpers/navigation_service.dart';

class AppRoutes {
  static GoRouter router = GoRouter(
    initialLocation: '/',
    navigatorKey: NavigationService.navigatorKey,
    routes: [
      // GoRoute(
      //   name: SplashScreen.routeName,
      //   path: '/',
      //   builder: (context, state) => const SplashScreen(),
      // ),
    ],
  );
}
