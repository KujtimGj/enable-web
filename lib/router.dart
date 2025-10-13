import 'package:enable_web/features/screens/account/account_file_upload.dart';
import 'package:enable_web/features/screens/agency/agency.dart';
import 'package:enable_web/features/screens/knowledgebase/bookmarks.dart';
import 'package:enable_web/features/screens/knowledgebase/chats.dart';
import 'package:enable_web/features/screens/knowledgebase/chat_detail.dart';
import 'package:enable_web/features/screens/knowledgebase/itinerary.dart';
import 'package:enable_web/features/screens/knowledgebase/products.dart';
import 'package:enable_web/features/screens/welcome/login_screen.dart';
import 'package:enable_web/features/screens/welcome/loginAgency.dart';
import 'package:enable_web/features/screens/home_screen.dart';
import 'package:enable_web/features/screens/dashboard_screen.dart';
import 'package:enable_web/features/screens/account/account.dart';
import 'package:enable_web/features/screens/account/dropbox_files_screen.dart';
import 'package:enable_web/features/screens/welcome/register.dart';
import 'package:enable_web/features/screens/welcome/welcome.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:enable_web/features/providers/userProvider.dart';
import 'package:enable_web/features/providers/agencyProvider.dart';
import 'package:enable_web/core/auth_utils.dart';

import 'features/screens/account/google_drive_files_screen.dart';
import 'features/screens/account/google_oauth_callback_screen.dart';
import 'features/screens/knowledgebase/vics.dart';

class GoRouteName {
  GoRouteName({
    required this.name,
    required this.path,
    this.authenticated = false,
  }) {
    _routeNamesByPath[path] = this;
  }

  final String name;
  final String path;
  final bool authenticated;

  static final _routeNamesByPath = <String, GoRouteName>{};

  static GoRouteName fromState(GoRouterState state) {
    return _routeNamesByPath[state.fullPath]!;
  }
}

GoRouteName routeRoot = GoRouteName(name: 'root', path: '/');

GoRouteName routeSignIn = GoRouteName(name: 'signin', path: '/signin');

GoRouteName routeHome = GoRouteName(
  name: 'home',
  path: '/home',
  authenticated: true,
);

GoRouteName routeConversations = GoRouteName(
  name: 'conversations',
  path: '/conversations',
  authenticated: true,
);

GoRouteName routeConversation = GoRouteName(
  name: 'conversation',
  path: '/conversations/:conversationId',
  authenticated: true,
);

GoRouteName routeBookmarks = GoRouteName(
  name: 'bookmarks',
  path: '/bookmarks',
  authenticated: true,
);

GoRouteName routeDashboard = GoRouteName(
  name: 'dashboard',
  path: '/dashboard',
  authenticated: true,
);

GoRouteName routeAccount = GoRouteName(
  name: 'account',
  path: '/account',
  authenticated: true,
);

GoRouteName routeUserManagement = GoRouteName(
  name: 'user-management',
  path: '/user-management',
  authenticated: true,
);

GoRouteName routeAccountFileUpload = GoRouteName(
  name: 'account-file-upload',
  path: '/account-file-upload',
  authenticated: true,
);

GoRouteName routeAccountUploadFile = GoRouteName(
  name: 'account-upload-file',
  path: '/account-upload-file',
  authenticated: true,
);

GoRouteName routeGoogleDriveFiles = GoRouteName(
  name: 'google-drive-files',
  path: '/google-drive-files',
  authenticated: true,
);

GoRouteName routeGoogleOAuthCallback = GoRouteName(
  name: 'google-oauth-callback',
  path: '/google/redirect',
  authenticated: true,
);

GoRouteName routeDropboxFiles = GoRouteName(
  name: 'dropbox-files',
  path: '/dropbox-files',
  authenticated: true,
);

GoRouteName routeVics = GoRouteName(
  name: 'vics',
  path: '/vics',
  authenticated: true,
);
GoRouteName routeRegister = GoRouteName(name: "register", path: "/register");

GoRouteName routeKnowledgebase = GoRouteName(
  name: "knowledgebase",
  path: '/knowledgebase',
  authenticated: true,
);

GoRouteName routeProducts = GoRouteName(
  name: "products",
  path: '/products',
  authenticated: true,
);

GoRouteName routeDMCs = GoRouteName(
  name: "dmcs",
  path: '/dmcs',
  authenticated: true,
);

GoRouteName routeExternalProducts = GoRouteName(
  name: "external-products",
  path: '/external-products',
  authenticated: true,
);

GoRouteName routeServiceProviders = GoRouteName(
  name: "service-providers",
  path: '/service-providers',
  authenticated: true,
);

GoRouteName routeExperiences = GoRouteName(
  name: "experiences",
  path: '/experiences',
  authenticated: true,
);

GoRouteName routeItinerary = GoRouteName(
  name: "itinerary",
  path: "/itinerary",
  authenticated: true,
);

GoRouteName agencyRoute = GoRouteName(
  name: "agencyRoute",
  path: "/agencyroute",
);

GoRouteName agencyLogin = GoRouteName(
  name: "agencylogin",
  path: "/agencylogin",
);

GoRouteName chatsRoute = GoRouteName(
    name: 'chats',
    path: '/chats',
    authenticated: true
);

GoRouteName chatDetailRoute = GoRouteName(name: 'chat-detail',
    path: '/knowledgebase/chats/:conversationId',
    authenticated: true
);

GoRouteName routeWelcome = GoRouteName(
    name: "welcome",
    path: "/welcome"
);

GoRouter createGoRouter({String? initialLocation}) {

  final routes = [
    // ---------------------------------
    // Root
    // ---------------------------------
    GoRoute(
      name: routeRoot.name,
      path: routeRoot.path,
      pageBuilder: (context, state) {
        return MaterialPage(
          child: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    ),
    // ---------------------------------
    // Welcome
    // ---------------------------------
    GoRoute(
      name: routeWelcome.name,
      path: routeWelcome.path,
      pageBuilder: (context, state) {
        return MaterialPage(child: Welcome());
      },
    ),
    // ---------------------------------
    // Agency View
    // ---------------------------------
    GoRoute(
      name: agencyRoute.name,
      path: agencyRoute.path,
      pageBuilder: (context, state) {
        return MaterialPage(child: AgencyView());
      },
    ),

    // ---------------------------------
    // Agency Login
    // ---------------------------------
    GoRoute(
      name: agencyLogin.name,
      path: agencyLogin.path,
      pageBuilder: (context, state) {
        return MaterialPage(child: const LoginAgency());
      },
    ),
    // ---------------------------------
    // Authentication
    // ---------------------------------
    GoRoute(
      name: routeSignIn.name,
      path: routeSignIn.path,
      pageBuilder: (context, state) {
        return MaterialPage(child: LoginScreen());
      },
    ),

    // ---------------------------------
    // Home
    // ---------------------------------
    GoRoute(
      name: routeHome.name,
      path: routeHome.path,
      pageBuilder: (context, state) {
        return MaterialPage(child: const HomeScreen());
      },
    ),
    // ---------------------------------
    // Dashboard
    // ---------------------------------
    GoRoute(
      name: routeDashboard.name,
      path: routeDashboard.path,
      pageBuilder: (context, state) {
        return MaterialPage(child: const DashboardScreen());
      },
    ),
    // ---------------------------------
    // Account
    // ---------------------------------
    // Note: Query parameters (e.g., ?dropboxTokenId=...) are not part of the route path.
    // They are accessible in the Account screen via Uri.base.queryParameters.
    GoRoute(
      name: routeAccount.name,
      path: routeAccount.path,
      pageBuilder: (context, state) {
        return MaterialPage(child: const Account());
      },
    ),

    // ---------------------------------
    // Account file upload
    // ---------------------------------
    GoRoute(
      name: routeAccountFileUpload.name,
      path: routeAccountFileUpload.path,
      pageBuilder: (context, state) {
        return MaterialPage(child: const AccountFileUpload());
      },
    ),

    // ---------------------------------
    // Account upload file (alternative path)
    // ---------------------------------
    GoRoute(
      name: routeAccountUploadFile.name,
      path: routeAccountUploadFile.path,
      pageBuilder: (context, state) {
        return MaterialPage(child: const AccountFileUpload());
      },
    ),

    // ---------------------------------
    // Google Drive Files
    // ---------------------------------
    GoRoute(
      name: routeGoogleDriveFiles.name,
      path: routeGoogleDriveFiles.path,
      pageBuilder: (context, state) {
        return MaterialPage(child: const GoogleDriveFilesScreen());
      },
    ),

    // ---------------------------------
    // Google OAuth Callback
    // ---------------------------------
    GoRoute(
      name: routeGoogleOAuthCallback.name,
      path: routeGoogleOAuthCallback.path,
      pageBuilder: (context, state) {
        return MaterialPage(child: const GoogleOAuthCallbackScreen());
      },
    ),

    // ---------------------------------
    // Dropbox Files
    // ---------------------------------
    GoRoute(
      name: routeDropboxFiles.name,
      path: routeDropboxFiles.path,
      pageBuilder: (context, state) {
        return MaterialPage(child: const DropboxFilesScreen());
      },
    ),
    // ---------------------------------
    // Vics
    // ---------------------------------
    GoRoute(
      path: routeVics.path,
      name: routeVics.name,
      pageBuilder: (context, state) {
        return MaterialPage(child: VICs());
      },
    ),
    // ---------------------------------
    // Register
    // ---------------------------------
    GoRoute(
      path: routeRegister.path,
      name: routeRegister.name,
      pageBuilder: (context, state) {
        return MaterialPage(child: Register());
      },
    ),

    // ---------------------------------
    // Itinerary
    // ---------------------------------

    GoRoute(
      path: routeItinerary.path,
      name: routeItinerary.name,
      pageBuilder: (context, state) {
        return MaterialPage(child: Itinerary());
      },
    ),
    // ---------------------------------
    // Chats
    // ---------------------------------
    GoRoute(
      path: chatsRoute.path,
      name: chatsRoute.name,
      pageBuilder: (context, state) {
        return MaterialPage(child: ChatsList());
      },
    ),
    // ---------------------------------
    // Chat Detail
    // ---------------------------------
    GoRoute(
      path: chatDetailRoute.path,
      name: chatDetailRoute.name,
      pageBuilder: (context, state) {
        final conversationId = state.pathParameters['conversationId']!;
        final conversationName = state.uri.queryParameters['name'] ?? 'Conversation';
        return MaterialPage(
          child: ChatDetailScreen(
            conversationId: conversationId,
            conversationName: conversationName,
          ),
        );
      },
    ),
    // ---------------------------------
    // Products
    // ---------------------------------
    GoRoute(
      path: routeProducts.path,
      name: routeProducts.name,
      pageBuilder: (context, state) {
        return MaterialPage(
          key: const ValueKey('products-page'),
          child: const Products(),
        );
      },
    ),
    // ---------------------------------
    // Bookmarks
    // ---------------------------------
    GoRoute(
      path: routeBookmarks.path,
      name: routeBookmarks.name,
      pageBuilder: (context,state){
        return MaterialPage(child: Bookmarks());
      }
    )
  ];
  

  final router = GoRouter(
    initialLocation: initialLocation ?? '/home',
    redirect: (context, state) {
      final unauthenticatedAllowedRoutes = [
        routeSignIn.path,
        routeRegister.path,
        agencyLogin.path,
        routeWelcome.path,
        routeKnowledgebase.path,
      ];

      if (unauthenticatedAllowedRoutes.contains(state.matchedLocation)) {
        return null;
      }

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final agencyProvider = Provider.of<AgencyProvider>(
          context,
          listen: false,
        );


        // Check if either provider is still loading or not initialized
        if (userProvider.isLoading ||
            !userProvider.isInitialized ||
            agencyProvider.isLoading ||
            !agencyProvider.isInitialized) {
          return null;
        }

        // Use the dynamic authentication function
        if (!AuthUtils.isAnyUserAuthenticated(context)) {
          return routeSignIn.path;
        }

        String? userType = AuthUtils.getCurrentUserType(context);


        if (userType == 'agency') {
          // Allow agency routes
          if (state.matchedLocation.startsWith('/agency')) {
            return null;
          }
          return '/agency';
        }

        if (userType == 'user') {
          return null;
        }

        return null;
      } catch (e) {
        return routeSignIn.path;
      }
    },
    routes: routes,
  );
  
  return router;
}
