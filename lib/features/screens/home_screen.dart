import 'package:enable_web/core/dimensions.dart';
import 'package:enable_web/features/components/widgets.dart';
import 'package:enable_web/features/providers/userProvider.dart';
import 'package:enable_web/features/providers/productProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:enable_web/core/responsive_utils.dart';
import 'package:enable_web/features/components/responsive_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:enable_web/core/auth_utils.dart';

import '../providers/agentProvider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void showAccountOverlay(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    OverlayState overlayState = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            bottom: 10,
            left: 10,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 240,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.circle_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        title: Text(
                          'Theme',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          overlayEntry?.remove();
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                          size: 20,
                        ),
                        title: Text(
                          'Settings',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          overlayEntry?.remove();
                        },
                      ),
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xff574435),
                          ),
                          child: Center(
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'User',
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              user?.email ?? 'user@example.com',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          context.go("/account");
                          overlayEntry?.remove();
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 20,
                        ),
                        title: Text(
                          'Logout',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () async {
                          final userProvider = Provider.of<UserProvider>(
                            context,
                            listen: false,
                          );
                          await userProvider.logout();
                          overlayEntry?.remove();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    overlayState.insert(overlayEntry);
  }

  String? id;
  getId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      id = prefs.getString('_id');
    });
  }

  final TextEditingController _chatController = TextEditingController();
  String _selectedSearchType = 'Mixed';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProducts();
    });
  }

  void _fetchProducts() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    if (userProvider.user?.agencyId != null) {
      productProvider.fetchProductsByAgencyId(userProvider.user!.agencyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        title: Text(
          'Enable',
          style: TextStyle(
            fontSize: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 20,
              tablet: 24,
              desktop: 26,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ResponsiveContainer(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final user = userProvider.user;

            return Row(
              children: [
                bottomLeftBar(),
                SizedBox(width: 5),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: getHeight(context),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Text(
                                  "Hi ${user?.name ?? 'User'}",
                                  style: TextStyle(fontSize: 20),
                                ),
                                // User type indicator
                                Text(
                                  "How can I help you?",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                // Display structured summary if available
                                Consumer<ChatProvider>(
                                  builder: (context, provider, _) {
                                    final structuredSummary = provider.structuredSummary;
                                    
                                    if (structuredSummary != null && structuredSummary.isNotEmpty) {
                                      return Container(
                                        width: getWidth(context),
                                        margin: EdgeInsets.symmetric(vertical: 10),
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Color(0xff1A1818),
                                          border: Border.all(color: Color(0xff292525)),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: SelectableText.rich(
                                          TextSpan(
                                            children: _parseMarkdownText(structuredSummary),
                                          ),
                                        ),
                                      );
                                    }
                                    
                                    return SizedBox.shrink();
                                  },
                                ),
                                Consumer<ChatProvider>(
                                  builder: (context, provider, _) {
                                    final messages = provider.messages;
                                    final error = provider.error;
                                    final structuredSummary = provider.structuredSummary;

                                    // Show error message if there's an error
                                    if (error != null) {
                                      return Container(
                                        width: getWidth(context),
                                        padding: EdgeInsets.all(16),
                                        margin: EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          border: Border.all(color: Colors.red[200]!),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row( 
                                              children: [
                                                Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                                                SizedBox(width: 8),
                                                Text(
                                                  'AI Service Error',
                                                  style: TextStyle(
                                                    color: Colors.red[700],
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              error.contains('AI service') 
                                                  ? error 
                                                  : 'There was an issue processing your request. Please try again.',
                                              style: TextStyle(
                                                color: Colors.red[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            TextButton(
                                              onPressed: () {
                                                provider.clearChat();
                                              },
                                              child: Text(
                                                'Try Again',
                                                style: TextStyle(color: Colors.red[600]),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    // Only show dummy conversations if no summary and no messages
                                    if (messages.isEmpty && structuredSummary == null) {
                                      // fallback to static chat suggestions
                                      return ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: 3,
                                        itemBuilder: (context, index) {
                                          return Container(
                                            width: getWidth(context),
                                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10,),
                                            margin: EdgeInsets.symmetric(vertical: 10,),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Color(0xff292525),),
                                              borderRadius: BorderRadius.circular(5,),
                                              color: Color(0xff1A1818)
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(10),
                                                  width: 30,
                                                  decoration: BoxDecoration(
                                                    color: Color(0xff292525),
                                                    borderRadius:
                                                        BorderRadius.circular(5),
                                                  ),
                                                  child: Center(
                                                    child: SvgPicture.asset(
                                                      'assets/icons/chat.svg',
                                                    ),
                                                  ),
                                                ),
                                                Text('New conversation'),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    }

                                    // Show actual messages if available
                                    if (messages.isNotEmpty) {
                                      return ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: messages.length,
                                        itemBuilder: (context, index) {
                                          final msg = messages[index];
                                          final isUser = msg['role'] == 'user';

                                          return Align(
                                            alignment:
                                                isUser
                                                    ? Alignment.centerRight
                                                    : Alignment.centerLeft,
                                            child: Container(
                                              constraints: BoxConstraints(
                                                maxWidth: getWidth(context) * 0.8,
                                              ),
                                              margin: EdgeInsets.symmetric(
                                                vertical: 6,
                                              ),
                                              padding: EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color:
                                                    isUser
                                                        ? Color(0xff292525)
                                                        : Color(0xff3a3a3a),
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(10),
                                                  topRight: Radius.circular(10),
                                                  bottomLeft:
                                                      isUser
                                                          ? Radius.circular(10)
                                                          : Radius.circular(0),
                                                  bottomRight:
                                                      isUser
                                                          ? Radius.circular(0)
                                                          : Radius.circular(10),
                                                ),
                                              ),
                                              child: Text(
                                                msg['content'] ?? '',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }

                                    return SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Input field and dropdown at the bottom
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: TextFormField(
                                  onFieldSubmitted: (value) async {
                                    final userProvider = Provider.of<UserProvider>(
                                      context,
                                      listen: false,
                                    );
                                    final chatProvider = Provider.of<ChatProvider>(
                                      context,
                                      listen: false,
                                    );

                                    final userId = userProvider.user!.id;
                                    final agencyId = userProvider.user!.agencyId;

                                    if (value.trim().isEmpty) return;

                                    print("User submitted query: $value");

                                    chatProvider.addUserMessage(value.trim());
                                    chatProvider.addAgentPlaceholder();

                                    _chatController.clear();

                                    await chatProvider.sendQuery(
                                      userId: userId,
                                      agencyId: agencyId,
                                      query: value.trim(),
                                    );
                                  },
                                  controller: _chatController,

                                  decoration: InputDecoration(
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SvgPicture.asset(
                                        'assets/icons/star-05.svg',
                                      ),
                                    ),
                                    hintText: 'Ask Enable',
                                    hintStyle: TextStyle(color: Colors.white),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xff383232),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                padding: EdgeInsets.all(5),
                                width: 160,
                                height: 30,
                                child: MenuAnchor(
                                  builder: (context, controller, child) {
                                    return InkWell(
                                      onTap: () {
                                        if (controller.isOpen) {
                                          controller.close();
                                        } else {
                                          controller.open();
                                        }
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _selectedSearchType,
                                            style: TextStyle(color: Colors.white),
                                          ),
                                          Icon(Icons.arrow_drop_down, color: Colors.white),
                                        ],
                                      ),
                                    );
                                  },
                                  menuChildren: [
                                    'Mixed',
                                    'AI Search',
                                    'My knowledge'
                                  ].map<Widget>((String value) {
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedSearchType = value;
                                        });
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                        child: Text(
                                          value,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: getHeight(context),
                    child: Consumer2<ChatProvider, ProductProvider>(
                      builder: (context, chatProvider, productProvider, child) {
                        final externalProducts = chatProvider.externalProducts;
                        final dbProducts = productProvider.products;

                        if (chatProvider.isLoading) {
                          return shimmerGrid();
                        }

                        if (externalProducts.isNotEmpty) {
                          return GridView.builder(
                            itemCount: externalProducts.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.5,
                                  mainAxisSpacing: 15,
                                  crossAxisSpacing: 15,
                                ),
                            itemBuilder: (context, index) {
                              final product = externalProducts[index];
                              final images =
                                  product['rawData']?['imageUrls'] ?? [];

                              return Container(
                                padding: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    width: 0.5,
                                    color: Colors.grey,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child:
                                          images.isNotEmpty
                                              ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Image.network(
                                                  images[0],
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                              : Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[800],
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  Icons.image,
                                                  color: Colors.white,
                                                ),
                                              ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['name'] ?? 'No Name',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              product['category'] ?? '',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }

                        if (dbProducts.isNotEmpty) {
                          return GridView.builder(
                            itemCount: dbProducts.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.5,
                                  mainAxisSpacing: 15,
                                  crossAxisSpacing: 15,
                                ),
                            itemBuilder: (context, index) {
                              final product = dbProducts[index];
                              final images = product.mediaPhotos;

                              return Container(
                                padding: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    width: 0.5,
                                    color: Colors.grey,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child:
                                          images != null && images.isNotEmpty
                                              ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Image.network(
                                                  images[0].imageUrl ?? images[0].signedUrl ?? '',
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      height: getHeight(context),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(10),
                                                      ),
                                                      child: Icon(
                                                        Icons.image,
                                                        color: Colors.white,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                              : Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[800],
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  Icons.image,
                                                  color: Colors.white,
                                                ),
                                              ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              product.category,
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            if (product.priceMin != null || product.priceMax != null)
                                              SizedBox(height: 2),
                                            if (product.priceMin != null && product.priceMax != null)
                                              Text(
                                                '\$${product.priceMin!.toStringAsFixed(2)} - \$${product.priceMax!.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.green[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              )
                                            else if (product.priceMin != null)
                                              Text(
                                                'From \$${product.priceMin!.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.green[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }

                        return shimmerGrid();
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget shimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Color(0xff363636),
          highlightColor: Colors.grey[900]!,
          child: Container(
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              border: Border.all(width: 0.5, color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Shimmer Image
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // Shimmer Text
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 15.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 60.0,
                          height: 15.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<TextSpan> _parseMarkdownText(String text) {
    if (text.isEmpty) return [];
    
    List<TextSpan> spans = [];
    String remainingText = text;
    
    while (remainingText.isNotEmpty) {
      // Check for ### headers first
      if (remainingText.startsWith('### ')) {
        // Find the end of the header (next line or end of text)
        int endIndex = remainingText.indexOf('\n');
        if (endIndex == -1) endIndex = remainingText.length;
        
        String headerText = remainingText.substring(4, endIndex);
        spans.add(TextSpan(
          text: headerText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ));
        
        // Add newline if there is one
        if (endIndex < remainingText.length && remainingText[endIndex] == '\n') {
          spans.add(TextSpan(text: '\n'));
          remainingText = remainingText.substring(endIndex + 1);
        } else {
          remainingText = remainingText.substring(endIndex);
        }
        continue;
      }
      
      // Check for **bold** text
      int boldStart = remainingText.indexOf('**');
      if (boldStart != -1) {
        // Add text before bold
        if (boldStart > 0) {
          spans.add(TextSpan(
            text: remainingText.substring(0, boldStart),
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ));
        }
        
        // Find end of bold text
        int boldEnd = remainingText.indexOf('**', boldStart + 2);
        if (boldEnd != -1) {
          String boldText = remainingText.substring(boldStart + 2, boldEnd);
          spans.add(TextSpan(
            text: boldText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ));
          remainingText = remainingText.substring(boldEnd + 2);
        } else {
          // No closing ** found, treat as regular text
          spans.add(TextSpan(
            text: remainingText.substring(boldStart, boldStart + 2),
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ));
          remainingText = remainingText.substring(boldStart + 2);
        }
        continue;
      }
      
      // No markdown found, add remaining text as regular text
      spans.add(TextSpan(
        text: remainingText,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          height: 1.4,
        ),
      ));
      break;
    }
    
    return spans;
  }
}
