class AppConstants {
  // App Info
  static const String appName = 'Enable';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String devApiUrl = 'http://localhost:3000/api';
  static const String prodApiUrl = 'https://your-nodejs-backend.com/api';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userProfileKey = 'user_profile';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Timeouts
  static const int connectionTimeout = 30; // seconds
  static const int receiveTimeout = 30; // seconds

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 50;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  static const double defaultIconSize = 24.0;
  
  // Responsive Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1600;
  
  // Responsive Spacing
  static const double mobileSpacing = 8.0;
  static const double tabletSpacing = 16.0;
  static const double desktopSpacing = 24.0;
  
  // Responsive Font Sizes
  static const double mobileFontSize = 14.0;
  static const double tabletFontSize = 16.0;
  static const double desktopFontSize = 18.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}