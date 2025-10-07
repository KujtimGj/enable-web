import 'package:enable_web/core/app_constants.dart';
import 'package:enable_web/features/providers/agencyProvider.dart';
import 'package:enable_web/features/providers/agentProvider.dart';
import 'package:enable_web/features/providers/dropbox_provider.dart';
import 'package:enable_web/features/providers/userProvider.dart';
import 'package:enable_web/features/providers/google_drive_provider.dart';
import 'package:enable_web/features/providers/vicProvider.dart';
import 'package:enable_web/features/providers/productProvider.dart';
import 'package:enable_web/features/providers/productsProvider.dart';
import 'package:enable_web/features/providers/bookmark_provider.dart';
import 'package:enable_web/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Cache the router instance to prevent recreation
  static final GoRouter _router = createGoRouter(initialLocation: '/home');

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => GoogleDriveProvider()),
        ChangeNotifierProvider(create: (_)=> DropboxProvider()),
        ChangeNotifierProvider(create: (_)=>AgencyProvider()),
        ChangeNotifierProvider(create: (_)=>ChatProvider()),
        ChangeNotifierProvider(create: (_)=>VICProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
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
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

