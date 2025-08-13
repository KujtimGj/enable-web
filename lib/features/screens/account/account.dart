// ignore_for_file: use_build_context_synchronously
import 'package:enable_web/core/dimensions.dart';
import 'package:enable_web/features/components/responsive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:enable_web/features/controllers/agencyController.dart';
import 'package:provider/provider.dart';
import '../../../core/responsive_utils.dart';
import '../../entities/user.dart';
import '../../providers/google_drive_provider.dart';
import '../../providers/dropbox_provider.dart';

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

  final AgencyController _agencyController = AgencyController();
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
    super.dispose();
  }

  @override
  void initState() {
    getUser();
    getToken();
    super.initState();
    
    // Check for OAuth callback after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForOAuthCallback();
    });
  }

  void _checkForOAuthCallback() {
    final uri = Uri.base;
    String? tokens;
    String? error;

    tokens = uri.queryParameters['tokens'];
    error = uri.queryParameters['error'];

    // If not found, try parsing from the fragment (hash route)
    if (uri.fragment.isNotEmpty) {
      final fragment = uri.fragment;
      final queryPart = fragment.contains('?') ? fragment.split('?')[1] : '';
      final fragmentParams = Uri.splitQueryString(queryPart);

      print('[Account] Fragment params: $fragmentParams');
      if (tokens == null) tokens = fragmentParams['tokens'];
      if (error == null) error = fragmentParams['error'];
     }

    print('[Account] Tokens found: ${tokens != null}');
    print('[Account] Error found: ${error != null}');

    if (error != null && error.isNotEmpty) {
      print('[Account] Processing error: $error');
      WidgetsBinding.instance.addPostFrameCallback((_) { 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Drive connection failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      });
    } else if (tokens != null && tokens.isNotEmpty) {
      print('[Account] Processing tokens...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleTokensReceived(tokens!);
      });
    } else {
      print('[Account] No tokens or error found');
    }
  }

  Future<void> _handleTokensReceived(String tokensJson) async {
    try {
      print('Handling tokens received: $tokensJson');
      
      // Decode the tokens from the URL parameter
      final decodedTokens = Uri.decodeComponent(tokensJson);
      print('Decoded tokens: $decodedTokens');
      
      final tokens = jsonDecode(decodedTokens);
      print('Parsed tokens: ${tokens.toString()}');
      
      final googleDriveProvider = Provider.of<GoogleDriveProvider>(
        context,
        listen: false,
      );
      
      // Associate the tokens directly
      await googleDriveProvider.associateGoogleDriveTokens(
        tokens['accessToken'],
        tokens['refreshToken'],
        tokens['expiryDate']?.toString(),
      );

      // Check if the connection was successful
      if (googleDriveProvider.isConnected) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Drive connected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the connection status
        await googleDriveProvider.checkConnectionStatus();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect Google Drive: ${googleDriveProvider.error ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {
      print('Error handling tokens: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect Google Drive: $e'),
          backgroundColor: Colors.red,
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



  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      return null;
    }
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
                                  if (googleDriveProvider.isConnected)
                                    Padding(
                                      padding: EdgeInsets.only(top: 10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (googleDriveProvider.lastSync !=
                                              null)
                                            Text(
                                              'Last sync: ${_formatDate(googleDriveProvider.lastSync!)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          GestureDetector(
                                            onTap:
                                                () => context.go(
                                                  '/google-drive-files',
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
}
