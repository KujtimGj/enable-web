// ignore_for_file: use_build_context_synchronously
import 'package:enable_web/core/dimensions.dart';
import 'package:enable_web/features/components/responsive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:provider/provider.dart';
import '../../../core/responsive_utils.dart';
import '../../entities/user.dart';
import '../../providers/google_drive_provider.dart';
import '../../providers/dropbox_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
 
class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  String email = '';
  String name = '';
  String phoneNumber = '';
  String logoUrl = '';
  String role = '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _logoController = TextEditingController();

  final bool _isLoading = false;

  getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson);
        final user = UserModel.fromJson(userMap);
        setState(() {
          email = user.email;
          name = user.name;
          role = user.role;

          // Update TextEditingControllers with the retrieved data
          _nameController.text = user.name;
          _emailController.text = user.email;
          _phoneController.text = user.role;
        });
      } catch (e) {
        setState(() {
          email = '';
          name = '';
          phoneNumber = '';
          _nameController.text = '';
          _emailController.text = '';
        });
      }
    } else {
      setState(() {
        email = '';
        name = '';
        _nameController.text = '';
        _emailController.text = '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _logoController.dispose();
    // Clean up message listener
    if (kIsWeb) {
      html.window.removeEventListener('message', _messageHandler);
    }
    super.dispose();
  }

  @override
  void initState() {
    getUser();
    getToken();
    super.initState();
    
    print('[Account] initState called, setting up message listener');
    
    // Set up message listener for OAuth callbacks
    if (kIsWeb) {
      print('[Account] Setting up message listener for web');
      // Remove any existing listeners first
      html.window.removeEventListener('message', _messageHandler);
      // Add the new listener
      html.window.addEventListener('message', _messageHandler);
      print('[Account] Message listener set up successfully');
    } else {
      print('[Account] Not web platform, skipping message listener');
    }
  }

  // Define the message handler as a separate method for proper cleanup
  void _messageHandler(html.Event event) {
    print('[Account] Message event received: $event');
    if (event is html.MessageEvent) {
      print('[Account] MessageEvent detected, calling handler');
      _handleOAuthMessage(event);
    } else {
      print('[Account] Event is not MessageEvent: ${event.runtimeType}');
    }
  }

  void _handleOAuthMessage(html.MessageEvent event) { 
    print('[Account] _handleOAuthMessage called with event: $event');
    print('[Account] Event origin: ${event.origin}');
    print('[Account] Event data: ${event.data}');
    
    // Accept messages from both localhost (dev) and Railway (production)
    final allowedOrigins = [
      'http://localhost:3000',
      'https://enable-be-production.up.railway.app'
    ];
    
    if (!allowedOrigins.contains(event.origin)) {
      print('[Account] Origin mismatch, expected one of: $allowedOrigins, got: ${event.origin}');
      return;
    }

    print('[Account] Origin verified, processing message');
    print('[Account] Received message from OAuth bridge: ${event.data}');
    
    // Handle the data as a Dart Map
    if (event.data is Map) {
      final data = event.data as Map;
      final messageType = data['type'];
      print('[Account] Message type: $messageType');
      
      if (messageType == 'GOOGLE_DRIVE_SUCCESS') {
        final tokens = data['tokens'];
        print('[Account] Processing OAuth success with tokens: $tokens');
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleOAuthSuccess(tokens);
        });
      } else if (messageType == 'GOOGLE_DRIVE_ERROR') {
        final error = data['error'];
        print('[Account] Processing OAuth error: $error');
        
        WidgetsBinding.instance.addPostFrameCallback((_) { 
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Google Drive connection failed: $error'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        });
      } else {
        print('[Account] Unknown message type: $messageType');
      }
    } else {
      print('[Account] Event data is not a Map: ${event.data.runtimeType}');
    }
  }

  Future<void> _handleOAuthSuccess(String tokenData) async {
    try {
      print('[Account] Handling OAuth success for token data: ${tokenData.length} chars');
      
      // Check if widget is still mounted before showing UI
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connecting to Google Drive...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
      
      final googleDriveProvider = Provider.of<GoogleDriveProvider>(
        context,
        listen: false,
      );
      
      final decodedTokens = Uri.decodeComponent(tokenData);
      print('[Account] Decoded tokens: ${decodedTokens.length} chars');
      final tokens = jsonDecode(decodedTokens);
      print('[Account] Parsed tokens: ${tokens.toString()}');
      print('[Account] Access token length: ${tokens['accessToken']?.length ?? 0}');
      print('[Account] Refresh token length: ${tokens['refreshToken']?.length ?? 0}');
      print('[Account] Calling associateGoogleDriveTokens...');
      
      await googleDriveProvider.associateGoogleDriveTokens(
        tokens['accessToken'],
        tokens['refreshToken'],
        tokens['expiryDate']?.toString(),
      );
      
      print('[Account] Connection status: ${googleDriveProvider.isConnected}');
      print('[Account] Error: ${googleDriveProvider.error}');
      
      // Check if widget is still mounted before showing UI
      if (!mounted) return;
      
      if (googleDriveProvider.isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Drive connected successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        await googleDriveProvider.checkConnectionStatus();
      } else {
        final errorMsg = googleDriveProvider.error ?? "Unknown error";
        print('[Account] Connection failed: $errorMsg');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect Google Drive: $errorMsg'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('[Account] Error handling OAuth success: $e');
      
      // Check if widget is still mounted before showing UI
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect Google Drive: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  getToken()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token;
    setState(() {
      token=prefs.getString('token');
    });
    print(token);
  }




  // Future<void> _handleOAuthCallback(String code) async {
  //   try {
  //     final googleDriveProvider = Provider.of<GoogleDriveProvider>(
  //       context,
  //       listen: false,
  //     );

  //     // Call backend to exchange code for tokenId
  //     final result = await googleDriveProvider.handleGoogleCallbackWithTokenId(code);

  //     if (result==true) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Google Drive connected successfully!'),
  //           backgroundColor: Colors.green,
  //         ),
  //       );
  //     } else {
  //       throw Exception("Token association failed.");
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Failed to connect Google Drive: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  // Future<void> _associateDropboxTokens(String tokenId) async {
  //   try {
  //     final dropboxProvider = Provider.of<DropboxProvider>(
  //       context,
  //       listen: false,
  //     );
  //     await dropboxProvider.associateDropboxTokens(tokenId);
  //     if (dropboxProvider.isConnected) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Dropbox connected successfully!'),
  //           backgroundColor: Colors.green,
  //         ),
  //       );
  //       // Remove dropboxTokenId from the URL after successful association
  //       try {
  //         final uri = Uri.base;
  //         if (uri.queryParameters.containsKey('dropboxTokenId')) {
  //           final newQueryParams = Map<String, String>.from(
  //             uri.queryParameters,
  //           );
  //           newQueryParams.remove('dropboxTokenId');
  //           final newUri = uri.replace(queryParameters: newQueryParams);
  //           html.window.history.replaceState(null, '', newUri.toString());
  //         }
  //       } catch (e) {
  //         print('Failed to clean up dropboxTokenId from URL: $e');
  //       }
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(
  //             'Failed to connect Dropbox: \'${dropboxProvider.error}\'',
  //           ),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Failed to connect Dropbox: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  int selectedIndex = 3;

  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      body: ResponsiveContainer(
        child: Padding(
          padding: EdgeInsets.only(top: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.go('/home');
                      },
                      child: Row(
                        children: [
                          SvgPicture.asset('assets/icons/go-back.svg'),
                          Text(
                            'Settings',
                            textAlign: TextAlign.start,
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = 0;
                        });
                      },
                      child: Container(
                        width: getWidth(context) * 0.70,
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color:
                              selectedIndex == 0
                                  ? Color(0xff2E2B2B)
                                  : Colors.transparent,
                          border: Border.all(color: Color(0xffE8DDC4)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text("Profile", style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = 1;
                        });
                      },
                      child: Container(
                        width: getWidth(context) * 0.70,
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color:
                              selectedIndex == 1
                                  ? Color(0xff2E2B2B)
                                  : Colors.transparent,
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text("Theme", style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = 2;
                        });
                      },
                      child: Container(
                        width: getWidth(context) * 0.70,
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color:
                              selectedIndex == 2
                                  ? Color(0xff2E2B2B)
                                  : Colors.transparent,
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text("Account", style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = 3;
                        });
                      },
                      child: Container(
                        width: getWidth(context) * 0.70,
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color:
                              selectedIndex == 3
                                  ? Color(0xff2E2B2B)
                                  : Colors.transparent,

                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Integrations",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 20),
              if (selectedIndex == 0)
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[600]!, width: 1),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SizedBox(width: 5),
                              Expanded(
                                flex: 1,
                                child: _buildTextField(
                                  'Full Name',
                                  _nameController,
                                  Icons.person,
                                  null,
                                  true,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: _buildTextField(
                                  'Email Address',
                                  _emailController,
                                  Icons.email,
                                  null,
                                  true,
                                ),
                              ),
                              SizedBox(width: 5),
                            ],
                          ),
                          SizedBox(height: 20),
                          _buildTextField(
                            'Phone Number',
                            _phoneController,
                            Icons.phone,
                            null,
                            true,
                          ),
                          SizedBox(height: 20),
                          _buildTextField(
                            'Logo URL',
                            _logoController,
                            Icons.image,
                            Icon(Icons.photo),
                            true,
                          ),
                          SizedBox(height: 30),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xff574131),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child:
                                    _isLoading
                                        ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : Text(
                                          'Save Changes',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (selectedIndex == 1)
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[600]!, width: 1),
                    ),
                  ),
                ),
              if (selectedIndex == 2)
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.all(20), 
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[600]!, width: 1),
                    ),
                  ),
                ),
              if (selectedIndex == 3)
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xff2E2B2B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[600]!, width: 1),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Integrations',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.responsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 16,
                                desktop: 18,
                              ),
                            ),
                          ),
                          Text(
                            'Allow Enable to reference other apps and services for more context.',
                          ),
                          SizedBox(height: 20),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey[600]!,
                          ),
                          SizedBox(height: 20),
                          Consumer<GoogleDriveProvider>(
                            builder: (context, googleDriveProvider, child) {
                              return Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          SvgPicture.asset(
                                            'assets/icons/drive2.svg',
                                            height: 20,
                                            width: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "Google Drive",
                                            style: TextStyle(
                                              fontSize:
                                                  ResponsiveUtils.responsiveFontSize(
                                                    context,
                                                    mobile: 14,
                                                    tablet: 16,
                                                    desktop: 18,
                                                  ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          // Live connection status indicator
                                          _buildConnectionStatusIndicator(googleDriveProvider),
                                        ],
                                      ),
                                      GestureDetector(
                                        onTap:
                                            googleDriveProvider.isLoading
                                                ? null
                                                : () {
                                                  if (googleDriveProvider
                                                      .isConnected) {
                                                    googleDriveProvider
                                                        .disconnectGoogleDrive();
                                                  } else {
                                                    googleDriveProvider
                                                        .connectGoogleDrive();
                                                  }
                                                },
                                        child: Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Color(0xff565859),
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                if (googleDriveProvider
                                                    .isLoading)
                                                  SizedBox(
                                                    width: 15,
                                                    height: 15,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                else
                                                  Text(
                                                    googleDriveProvider
                                                            .isConnected
                                                        ? 'Disconnect'
                                                        : 'Connect',
                                                  ),
                                                SizedBox(width: 5),
                                                if (!googleDriveProvider
                                                    .isLoading)
                                                  SvgPicture.asset(
                                                    'assets/icons/out.svg',
                                                    height: 15,
                                                    width: 15,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (googleDriveProvider.error != null)
                                    Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              googleDriveProvider.error!
                                                      .contains(
                                                        'opened in browser',
                                                      )
                                                  ? Colors.blue.shade100
                                                  : Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          googleDriveProvider.error!,
                                          style: TextStyle(
                                            color:
                                                googleDriveProvider.error!
                                                        .contains(
                                                          'opened in browser',
                                                        )
                                                    ? Colors.blue.shade800
                                                    : Colors.red.shade800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Connection status details
                                  Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Column(
                                      children: [
                                        // Connection status message
                                        if (googleDriveProvider.connectionStatusMessage != null)
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.all(8),
                                            margin: EdgeInsets.only(bottom: 8),
                                            decoration: BoxDecoration(
                                              color: googleDriveProvider.isConnected 
                                                  ? Colors.green.shade50
                                                  : googleDriveProvider.tokenExpired
                                                      ? Colors.red.shade50
                                                      : googleDriveProvider.hasConnectionIssues
                                                          ? Colors.red.shade50
                                                          : Colors.orange.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: googleDriveProvider.isConnected 
                                                    ? Colors.green.shade200
                                                    : googleDriveProvider.tokenExpired
                                                        ? Colors.red.shade200
                                                        : googleDriveProvider.hasConnectionIssues
                                                            ? Colors.red.shade200
                                                            : Colors.orange.shade200,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  googleDriveProvider.isConnected 
                                                      ? Icons.check_circle
                                                      : googleDriveProvider.tokenExpired
                                                          ? Icons.refresh
                                                          : googleDriveProvider.hasConnectionIssues
                                                              ? Icons.error
                                                              : Icons.warning,
                                                  size: 16,
                                                  color: googleDriveProvider.isConnected 
                                                      ? Colors.green.shade700
                                                      : googleDriveProvider.tokenExpired
                                                          ? Colors.red.shade700
                                                          : googleDriveProvider.hasConnectionIssues
                                                              ? Colors.red.shade700
                                                              : Colors.orange.shade700,
                                                ),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    googleDriveProvider.connectionStatusMessage!,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: googleDriveProvider.isConnected 
                                                          ? Colors.green.shade700
                                                          : googleDriveProvider.tokenExpired
                                                              ? Colors.red.shade700
                                                              : googleDriveProvider.hasConnectionIssues
                                                                  ? Colors.red.shade700
                                                                  : Colors.orange.shade700,
                                                    ),
                                                  ),
                                                ),
                                                if (googleDriveProvider.tokenExpired)
                                                  GestureDetector(
                                                    onTap: () => googleDriveProvider.connectGoogleDrive(),
                                                    child: Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red.shade700,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        'Reconnect',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                if (googleDriveProvider.isMonitoringConnection && !googleDriveProvider.tokenExpired)
                                                  SizedBox(
                                                    width: 12,
                                                    height: 12,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                        googleDriveProvider.isConnected 
                                                            ? Colors.green.shade700
                                                            : Colors.orange.shade700,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        // Last check and sync info
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            if (googleDriveProvider.isConnected)
                                              GestureDetector(
                                                onTap: () => context.go('/google-drive-files'),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Color(0xff574131),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'View Files',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: 20),
                          Consumer<DropboxProvider>(
                            builder: (context, dropboxProvider, child) {
                              return Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          SvgPicture.asset(
                                            'assets/icons/dropbox.svg',
                                            height: 20,
                                            width: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "Dropbox",
                                            style: TextStyle(
                                              fontSize:
                                                  ResponsiveUtils.responsiveFontSize(
                                                    context,
                                                    mobile: 14,
                                                    tablet: 16,
                                                    desktop: 18,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      GestureDetector(
                                        onTap:
                                            dropboxProvider.isLoading
                                                ? null
                                                : () {
                                                  if (dropboxProvider
                                                      .isConnected) {
                                                    dropboxProvider
                                                        .disconnectDropbox();
                                                  } else {
                                                    dropboxProvider
                                                        .connectDropbox();
                                                  }
                                                },
                                        child: Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Color(0xff565859),
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                if (dropboxProvider.isLoading)
                                                  SizedBox(
                                                    width: 15,
                                                    height: 15,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                else
                                                  Text(
                                                    dropboxProvider.isConnected
                                                        ? 'Disconnect'
                                                        : 'Connect',
                                                  ),
                                                SizedBox(width: 5),
                                                if (!dropboxProvider.isLoading)
                                                  SvgPicture.asset(
                                                    'assets/icons/out.svg',
                                                    height: 15,
                                                    width: 15,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (dropboxProvider.error != null)
                                    Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              dropboxProvider.error!.contains(
                                                    'opened in browser',
                                                  )
                                                  ? Colors.blue.shade100
                                                  : Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          dropboxProvider.error!,
                                          style: TextStyle(
                                            color:
                                                dropboxProvider.error!.contains(
                                                      'opened in browser',
                                                    )
                                                    ? Colors.blue.shade800
                                                    : Colors.red.shade800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (dropboxProvider.isConnected)
                                    Padding(
                                      padding: EdgeInsets.only(top: 10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (dropboxProvider.lastSync != null)
                                            Text(
                                              'Last sync: ${_formatDate(dropboxProvider.lastSync!)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          GestureDetector(
                                            onTap:
                                                () => context.go(
                                                  '/dropbox-files',
                                                ),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Color(0xff574131),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'View Files',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/gmail.svg',
                                    height: 15,
                                    width: 15,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Gmail",
                                    style: TextStyle(
                                      fontSize:
                                          ResponsiveUtils.responsiveFontSize(
                                            context,
                                            mobile: 14,
                                            tablet: 16,
                                            desktop: 18,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Color(0xff565859),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text('Connect'),
                                      SizedBox(width: 5),
                                      SvgPicture.asset(
                                        'assets/icons/out.svg',
                                        height: 15,
                                        width: 15,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Upload local files"),
                              GestureDetector(
                                onTap: (){
                                  context.go("/account-upload-file");
                                },
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Color(0xff565859)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/upload.svg',
                                        height: 15,
                                        width: 15,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "Upload Local File",
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget formField(String hintText, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: Colors.grey[500]!, width: 1),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData? icon, Widget? suffixIc, bool fill,) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: label,
            suffixIcon: suffixIc,
            filled: fill,
            fillColor: Color(0xff262624),
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildConnectionStatusIndicator(GoogleDriveProvider provider) {
    if (provider.isLoading) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    Color indicatorColor;
    IconData indicatorIcon;
    String tooltip;

    if (provider.isConnected) {
      indicatorColor = Colors.green;
      indicatorIcon = Icons.check_circle;
      tooltip = 'Connected to Google Drive';
    } else if (provider.tokenExpired) {
      indicatorColor = Colors.red;
      indicatorIcon = Icons.refresh;
      tooltip = 'Token expired - Click to reconnect';
    } else if (provider.hasConnectionIssues) {
      indicatorColor = Colors.red;
      indicatorIcon = Icons.error;
      tooltip = 'Connection issues detected';
    } else {
      indicatorColor = Colors.orange;
      indicatorIcon = Icons.warning;
      tooltip = 'Not connected to Google Drive';
    }

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: provider.tokenExpired ? () => provider.connectGoogleDrive() : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              indicatorIcon,
              size: 16,
              color: indicatorColor,
            ),
            if (provider.isMonitoringConnection && !provider.tokenExpired) ...[
              SizedBox(width: 4),
              SizedBox(
                width: 8,
                height: 8,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
