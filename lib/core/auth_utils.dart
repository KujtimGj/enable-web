import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/providers/userProvider.dart';
import '../features/providers/agencyProvider.dart';

class AuthUtils {
  /// Dynamic function that checks if someone is logged in as either a user or an agency
  /// Returns true if the user is authenticated as either a regular user or an agency
  static bool isAnyUserAuthenticated(BuildContext context) {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
      
      return userProvider.isAuthenticated || agencyProvider.isAuthenticated;
    } catch (e) {
      print('Error checking authentication status: $e');
      return false;
    }
  }

  static String? getCurrentUserType(BuildContext context) {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
      
      if (userProvider.isAuthenticated) {
        return 'user';
      } else if (agencyProvider.isAuthenticated) {
        return 'agency';
      }
      return null;
    } catch (e) {
      print('Error getting user type: $e');
      return null;
    }
  }

  /// Check if the current user is authenticated as a regular user
  static bool isUserAuthenticated(BuildContext context) {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      return userProvider.isAuthenticated;
    } catch (e) {
      print('Error checking user authentication: $e');
      return false;
    }
  }

  /// Check if the current user is authenticated as an agency
  static bool isAgencyAuthenticated(BuildContext context) {
    try {
      final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
      return agencyProvider.isAuthenticated;
    } catch (e) {
      print('Error checking agency authentication: $e');
      return false;
    }
  }

  /// Get the current authenticated user object (either UserModel or AgencyModel)
  static dynamic getCurrentUser(BuildContext context) {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
      
      if (userProvider.isAuthenticated) {
        return userProvider.user;
      } else if (agencyProvider.isAuthenticated) {
        return agencyProvider.agency;
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Logout both user and agency (clears all authentication)
  static Future<void> logoutAll(BuildContext context) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
      
      // Logout from both providers
      await userProvider.logout();
      await agencyProvider.logoutAgency();
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}
