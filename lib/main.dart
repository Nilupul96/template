import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:template/core/app_theme.dart';
import 'core/app_providers.dart';
import 'core/app_routes.dart';
import 'core/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
        designSize: const Size(392, 783),
        minTextAdapt: true,
        builder: (_, child) {
          return MultiProvider(
              providers: AppProviders.providers,
              child: MaterialApp.router(
                title: 'Template',
                theme: AppTheme.appLightTheme,
                darkTheme: AppTheme.darkTheme,
                routerConfig: AppRoutes.router,
              ));
        });
  }
}
