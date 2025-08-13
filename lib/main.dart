import 'package:enable_web/core/app_constants.dart';
import 'package:enable_web/core/auth_utils.dart';
import 'package:enable_web/features/providers/agencyProvider.dart';
import 'package:enable_web/features/providers/agentProvider.dart';
import 'package:enable_web/features/providers/dropbox_provider.dart';
import 'package:enable_web/features/providers/userProvider.dart';
import 'package:enable_web/features/providers/google_drive_provider.dart';
import 'package:enable_web/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // String _getInitialLocation(BuildContext context) {
  //   if (Uri.base.fragment.isNotEmpty && Uri.base.fragment.startsWith('/')) {
  //     final route = Uri.base.fragment.split('?')[0];

  //     if (AuthUtils.isAnyUserAuthenticated(context)) {
  //       return route;
  //     } else {
  //       return '/welcome';
  //     }
  //   }

  //   if (!AuthUtils.isAnyUserAuthenticated(context)) {
  //     return '/welcome';
  //   }

  //   String? userType = AuthUtils.getCurrentUserType(context);
  //   if (userType == 'agency') {
  //     return '/agencyroute';
  //   } else if (userType == 'user') {
  //     return '/home';
  //   }

  //   return '/welcome';
  // }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => GoogleDriveProvider()),
        ChangeNotifierProvider(create: (_)=> DropboxProvider()),
        ChangeNotifierProvider(create: (_)=>AgencyProvider()),
        ChangeNotifierProvider(create: (_)=>ChatProvider())
      ],
      child: Consumer2<UserProvider, AgencyProvider>(
        builder: (context, userProvider, agencyProvider, child) {
          if (userProvider.isLoading || !userProvider.isInitialized ||
              agencyProvider.isLoading || !agencyProvider.isInitialized) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: AppConstants.appName,
              theme: EnableTheme.defaultTheme(context),
              home: const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: AppConstants.appName,
            theme: EnableTheme.defaultTheme(context),
            routerConfig: createGoRouter(
              initialLocation: '/home',
            ),
          );
        },
      ),
    );
  }
}

