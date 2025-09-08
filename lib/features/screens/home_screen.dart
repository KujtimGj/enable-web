import 'package:enable_web/core/dimensions.dart';
import 'package:enable_web/features/components/widgets.dart';
import 'package:enable_web/features/providers/userProvider.dart';
import 'package:enable_web/features/providers/productProvider.dart';
import 'package:enable_web/features/components/bookmark_components.dart';
import 'package:enable_web/features/providers/bookmark_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:enable_web/core/responsive_utils.dart';
import 'package:enable_web/features/components/responsive_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

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
  String _selectedSearchType = 'Knowledgebase';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProducts();
      _fetchConversations();
    });
  }

  void _fetchProducts() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    if (userProvider.user?.agencyId != null) {
      productProvider.fetchProductsByAgencyId(userProvider.user!.agencyId);
    }
  }

  void _fetchConversations() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (userProvider.user?.agencyId != null) {
      chatProvider.fetchConversations(userProvider.user!.agencyId, limit: 3); // Only show 3 on home screen
    }
  }

  void _showProductDetailModal(BuildContext context, dynamic product, bool isExternalProduct) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ProductDetailModal(product: product, isExternalProduct: isExternalProduct);
      },
    );
  }

  void _startNewConversation(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Clear the current conversation and start fresh
    chatProvider.startNewConversation();
    
    // Show a brief confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New conversation started'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  bool isHovered=false;
  
  // Helper methods for grid view product cards
  String _getProductName(dynamic product, bool isExternal) {
    if (product == null) return 'No Name';
    
    try {
      if (isExternal) {
        return product['name']?.toString() ?? 'No Name';
      } else {
        if (product is Map) {
          return product['name']?.toString() ?? 'No Name';
        } else {
          return product.name?.toString() ?? 'No Name';
        }
      }
    } catch (e) {
      return 'No Name';
    }
  }

  String _getProductCategory(dynamic product, bool isExternal) {
    if (product == null) return '';
    
    try {
      if (isExternal) {
        return product['category']?.toString() ?? '';
      } else {
        if (product is Map) {
          return product['category']?.toString() ?? '';
        } else {
          String category = product.category?.toString() ?? '';
          return category.isNotEmpty ? category[0].toUpperCase() + category.substring(1) : '';
        }
      }
    } catch (e) {
      return '';
    }
  }

  String _getProductCountry(dynamic product) {
    if (product == null) return '';
    
    try {
      if (product is Map) {
        return product['country']?.toString() ?? '';
      } else {
        String country = product.country?.toString() ?? '';
        return country.isNotEmpty ? country[0].toUpperCase() + country.substring(1) : '';
      }
    } catch (e) {
      return '';
    }
  }

  String _getProductCity(dynamic product) {
    if (product == null) return '';
    
    try {
      if (product is Map) {
        return product['city']?.toString() ?? '';
      } else {
        String city = product.city?.toString() ?? '';
        return city.isNotEmpty ? city[0].toUpperCase() + city.substring(1) : '';
      }
    } catch (e) {
      return '';
    }
  }

  double? _getProductPriceMin(dynamic product) {
    if (product == null) return null;
    
    try {
      if (product is Map) {
        return product['priceMin']?.toDouble();
      } else {
        return product.priceMin?.toDouble();
      }
    } catch (e) {
      return null;
    }
  }

  double? _getProductPriceMax(dynamic product) {
    if (product == null) return null;
    
    try {
      if (product is Map) {
        return product['priceMax']?.toDouble();
      } else {
        return product.priceMax?.toDouble();
      }
    } catch (e) {
      return null;
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
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              // Show button only when there's an active conversation
              if (chatProvider.conversationId != null || chatProvider.messages.isNotEmpty) {
                return customButton(()=>_startNewConversation(context));
              }
              return SizedBox.shrink();
            },
          ),
        ],
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
                                // Removed duplicate structured summary display - now only shown in messages below
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

                                    // Show conversations if no summary and no messages
                                    if (messages.isEmpty && structuredSummary == null) {
                                      // Show loading state
                                      if (provider.isLoadingConversations) {
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
                                              child: Shimmer.fromColors(
                                                baseColor: Color(0xff292525),
                                                highlightColor: Color(0xff3a3a3a),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      height: 30,
                                                      width: 30,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(5),
                                                      ),
                                                    ),
                                                    SizedBox(height: 10),
                                                    Container(
                                                      height: 16,
                                                      width: 120,
                                                      color: Colors.white,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }
                                      
                                      // Show real conversations if available
                                      if (provider.conversations.isNotEmpty) {
                                        return ListView.builder(
                                          shrinkWrap: true,
                                          physics: NeverScrollableScrollPhysics(),
                                          itemCount: provider.conversations.length,
                                          itemBuilder: (context, index) {
                                            final conversation = provider.conversations[index];
                                            final conversationName = conversation['name'] ?? 'Conversation ${index + 1}';
                                            
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
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.all(10),
                                                    width: 30,
                                                    decoration: BoxDecoration(
                                                      color: Color(0xff292525),
                                                      borderRadius: BorderRadius.circular(5),
                                                    ),
                                                    child: Center(
                                                      child: SvgPicture.asset(
                                                        'assets/icons/chat.svg',
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    conversationName,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      }
                                      
                                      // Fallback to static chat suggestions if no conversations
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
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(10),
                                                  width: 30,
                                                  decoration: BoxDecoration(
                                                    color: Color(0xff292525),
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                  child: Center(
                                                    child: SvgPicture.asset(
                                                      'assets/icons/chat.svg',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'New conversation',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    }

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
                                                color: isUser
                                                    ? Color(0xff292525)
                                                    : Colors.transparent, // Transparent background for AI responses
                                                border: isUser
                                                    ? null
                                                    : Border.all(
                                                        color: Color(0xff292525),
                                                        width: 1,
                                                      ), // Border only for AI responses
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
                                              child: RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                  children: _parseMarkdownText(msg['content'] ?? ''),
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

                                    chatProvider.addUserMessage(value.trim());
                                    chatProvider.addAgentPlaceholder();

                                    _chatController.clear();

                                    await chatProvider.sendQueryWithMode(
                                      userId: userId,
                                      agencyId: agencyId,
                                      query: value.trim(),
                                      searchMode: _selectedSearchType,
                                      existingConversationId: chatProvider.conversationId,
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
                                    'External Search',
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
                    child: Consumer3<ChatProvider, ProductProvider, BookmarkProvider>(
                      builder: (context, chatProvider, productProvider, bookmarkProvider, child) {
                        final externalProducts = chatProvider.externalProducts;
                        final dbProducts = productProvider.products;

                        // Prepare items for multi-select
                        final allItems = <Map<String, String>>[];
                        for (final product in externalProducts) {
                          final productId = product['_id']?.toString() ?? product['id']?.toString();
                          if (productId != null) {
                            allItems.add({
                              'itemType': 'externalProduct',
                              'itemId': productId,
                            });
                          }
                        }
                        for (final product in dbProducts) {
                          final productId = product.id.toString();
                          allItems.add({
                            'itemType': 'product',
                            'itemId': productId,
                          });
                        }

                        return Column(
                          children: [
                            // Multi-select toolbar
                            MultiSelectToolbar(
                              selectedCount: bookmarkProvider.selectedCount,
                              isMultiSelectMode: bookmarkProvider.isMultiSelectMode,
                              onToggleMultiSelect: () => bookmarkProvider.toggleMultiSelectMode(),
                              onSelectAll: () => bookmarkProvider.selectAllItems(allItems),
                              onClearSelection: () => bookmarkProvider.clearSelection(),
                              onBulkBookmark: () => _showBulkBookmarkDialog(context, bookmarkProvider),
                              onBulkDelete: () => _handleBulkDelete(context, bookmarkProvider),
                              hasBookmarks: _hasSelectedBookmarks(bookmarkProvider),
                            ),
                            
                            // Grid content
                            Expanded(
                              child: _buildGridContent(
                                chatProvider, 
                                productProvider, 
                                bookmarkProvider,
                                externalProducts, 
                                dbProducts
                              ),
                            ),
                          ],
                        );
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

  Widget _buildImageItem(List<dynamic> images, int index) {
     if (index >= images.length) {
       return Container(
         width: double.infinity,
         height: double.infinity,
         decoration: BoxDecoration(
           color: Colors.grey[800],
           borderRadius: BorderRadius.circular(8),
         ),
         child: Icon(
           Icons.image,
           color: Colors.white,
           size: 20,
         ),
       );
     }
     
     return ClipRRect(
       borderRadius: BorderRadius.circular(8),
       child: Image.network(
         images[index],
         width: double.infinity,
         height: double.infinity,
         fit: BoxFit.cover,
         errorBuilder: (context, error, stackTrace) {
           return Container(
             width: double.infinity,
             height: double.infinity,
             decoration: BoxDecoration(
               color: Colors.grey[800],
               borderRadius: BorderRadius.circular(8),
             ),
             child: Icon(
               Icons.image,
               color: Colors.white,
               size: 20,
             ),
           );
         },
       ),
     );
   }

   Widget _buildDatabaseImageItem(List<dynamic> images, int index) {
     if (index >= images.length) {
       return Container(
         width: double.infinity,
         height: double.infinity,
         decoration: BoxDecoration(
           color: Colors.grey[800],
           borderRadius: BorderRadius.circular(8),
         ),
         child: Icon(
           Icons.image,
           color: Colors.white,
           size: 20,
         ),
       );
     }
     
     return ClipRRect(
       borderRadius: BorderRadius.circular(8),
       child: Image.network(
          images[index].signedUrl,
         width: double.infinity,
         height: double.infinity,
         fit: BoxFit.cover,
         errorBuilder: (context, error, stackTrace) {
           return Container(
             width: double.infinity,
             height: double.infinity,
             decoration: BoxDecoration(
               color: Colors.grey[800],
               borderRadius: BorderRadius.circular(8),
             ),
             child: Icon(
               Icons.image,
               color: Colors.white,
               size: 20,
             ),
           );
         },
       ),
     );
   }

  List<TextSpan> _parseMarkdownText(String text) {
    if (text.isEmpty) return [];

    List<TextSpan> spans = [];
    String remainingText = text;

    while (remainingText.isNotEmpty) {
      // ### headers
      if (remainingText.startsWith('###')) {
        int endIndex = remainingText.indexOf('\n');
        if (endIndex == -1) endIndex = remainingText.length;

        String headerText = remainingText.substring(3, endIndex).trim();
        spans.add(TextSpan(
          text: headerText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,        // larger
            fontWeight: FontWeight.w900, // extra bold
            height: 1.6,
          ),
        ));

        if (endIndex < remainingText.length && remainingText[endIndex] == '\n') {
          spans.add(const TextSpan(text: '\n'));
          remainingText = remainingText.substring(endIndex + 1);
        } else {
          remainingText = remainingText.substring(endIndex);
        }
        continue;
      }

      // **bold** simplified handling
      int boldStart = remainingText.indexOf('**');
      if (boldStart != -1) {
        if (boldStart > 0) {
          spans.add(TextSpan(
            text: remainingText.substring(0, boldStart),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ));
        }

        int boldEnd = remainingText.indexOf('**', boldStart + 2);
        if (boldEnd != -1) {
          String boldText = remainingText.substring(boldStart + 2, boldEnd);
          spans.add(TextSpan(
            text: boldText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ));
          remainingText = remainingText.substring(boldEnd + 2);
        } else {
          spans.add(TextSpan(
            text: remainingText.substring(boldStart, boldStart + 2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ));
          remainingText = remainingText.substring(boldStart + 2);
        }
        continue;
      }

      // plain text
      spans.add(TextSpan(
        text: remainingText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          height: 1.4,
        ),
      ));
      break;
    }
    return spans;
  }

  Widget _buildCardBookmarkButton(dynamic product, bool isExternalProduct) {
    // Get product ID safely
    String? productId;
    try {
      if (isExternalProduct) {
        productId = product['_id']?.toString() ?? product['id']?.toString();
      } else {
        if (product is Map) {
          productId = product['_id']?.toString() ?? product['id']?.toString();
        } else {
          productId = product.id?.toString();
        }
      }
    } catch (e) {
      print('Error getting product ID: $e');
      return SizedBox.shrink();
    }

    if (productId == null) {
      print('HomeScreen: Product ID is null, returning empty widget');
      return SizedBox.shrink();
    }

    return BookmarkButton(
      itemType: isExternalProduct ? 'externalProduct' : 'product',
      itemId: productId,
      color: Colors.white70,
      activeColor: Colors.amber,
      size: 20,
    );
  }

  Widget _buildGridContent(ChatProvider chatProvider, ProductProvider productProvider, BookmarkProvider bookmarkProvider, List<dynamic> externalProducts, List<dynamic> dbProducts,) {
    if (chatProvider.isLoading) {
      return shimmerGrid();
    }

    if (externalProducts.isNotEmpty) {
      return _buildExternalProductsGrid(externalProducts, bookmarkProvider);
    }

    if (dbProducts.isNotEmpty) {
      return _buildDatabaseProductsGrid(dbProducts, bookmarkProvider);
    }

    return shimmerGrid();
  }

  Widget _buildExternalProductsGrid(List<dynamic> externalProducts, BookmarkProvider bookmarkProvider) {
    return GridView.builder(
      itemCount: externalProducts.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      itemBuilder: (context, index) {
        final product = externalProducts[index];
        final productId = product['_id']?.toString() ?? product['id']?.toString();
        final isSelected = bookmarkProvider.isItemSelected('externalProduct', productId ?? '');
        
        // Check if this is a database product (has images field) or external product (has rawData.imageUrls)
        List<String> images = [];
        if (product['images'] != null && product['images'].isNotEmpty) {
          // Database product - use signed URLs from images field
          for (var img in product['images']) {
            if (img is Map && img['signedUrl'] != null) {
              images.add(img['signedUrl'].toString());
            } else if (img.signedUrl != null) {
              images.add(img.signedUrl.toString());
            }
          }
        } else {
          // External product - use imageUrls from rawData
          images = (product['rawData']?['imageUrls'] ?? []).map((url) => url.toString()).toList().cast<String>();
        }

        return Stack(
          children: [
            InkWell(
              onTap: () {
                if (bookmarkProvider.isMultiSelectMode) {
                  bookmarkProvider.toggleItemSelection('externalProduct', productId ?? '');
                } else {
                  _showProductDetailModal(context, product, product['images'] == null || product['images'].isEmpty);
                }
              },
              child: Container(
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: isSelected ? 2 : 0.5,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    // 4 images grid on the left side
                    Expanded(
                      flex: 1,
                      child: images.isNotEmpty
                          ? Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: _buildImageItem(images, 0),
                                      ),
                                      SizedBox(height: 4),
                                      Expanded(
                                        child: _buildImageItem(images, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: _buildImageItem(images, 1),
                                      ),
                                      SizedBox(height: 4),
                                      Expanded(
                                        child: _buildImageItem(images, 3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                        : Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.image,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                    ),
                    // Product details on the right side
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _getProductName(product, true),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Bookmark button for external products
                                if (!bookmarkProvider.isMultiSelectMode)
                                  _buildCardBookmarkButton(product, true),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              _getProductCategory(product, true),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Multi-select checkbox
            if (bookmarkProvider.isMultiSelectMode)
              Positioned(
                top: 8,
                right: 8,
                child: MultiSelectBookmarkButton(
                  itemType: 'externalProduct',
                  itemId: productId ?? '',
                  isSelected: isSelected,
                  onTap: () => bookmarkProvider.toggleItemSelection('externalProduct', productId ?? ''),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDatabaseProductsGrid(List<dynamic> dbProducts, BookmarkProvider bookmarkProvider) {
    return GridView.builder(
      itemCount: dbProducts.length > 50 ? 35 : dbProducts.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      itemBuilder: (context, index) {
        final product = dbProducts[index];
        final images = product.images;
        final productId = product.id.toString();
        final isSelected = bookmarkProvider.isItemSelected('product', productId);

        return Stack(
          children: [
            MouseRegion(
              onEnter: (_) => setState(() => isHovered = true),
              onExit: (_) => setState(() => isHovered = false),
              child: InkWell(
                onTap: () {
                  if (bookmarkProvider.isMultiSelectMode) {
                    bookmarkProvider.toggleItemSelection('product', productId);
                  } else {
                    _showProductDetailModal(context, product, false);
                  }
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: Color(0xFF181616),
                    border: Border.all(
                      width: isSelected ? 2 : 0.5,
                      color: isSelected ? Colors.blue : Colors.grey,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isHovered
                        ? [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: images != null && images.isNotEmpty
                            ? Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: _buildDatabaseImageItem(images, 0),
                                        ),
                                        SizedBox(height: 4),
                                        Expanded(
                                          child: _buildDatabaseImageItem(images, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: _buildDatabaseImageItem(images, 1),
                                        ),
                                        SizedBox(height: 4),
                                        Expanded(
                                          child: _buildDatabaseImageItem(images, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                          : Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.image,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                      ),
                      // Product details on the right side
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    width: 30,
                                    decoration: BoxDecoration(
                                      color: Color(0xff292525),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'assets/icons/chat.svg',
                                      ),
                                    ),
                                  ),
                                  // Bookmark button for database products
                                  if (!bookmarkProvider.isMultiSelectMode)
                                    _buildCardBookmarkButton(product, false),
                                ],
                              ),
                              SizedBox(height: 10),
                              Text(
                                _getProductName(product, false),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 10),
                              Text(
                                _getProductCategory(product, false),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                              if (_getProductPriceMin(product) != null || _getProductPriceMax(product) != null)
                                SizedBox(height: 2),
                              if (_getProductPriceMin(product) != null && _getProductPriceMax(product) != null)
                                Text(
                                  '\$${_getProductPriceMin(product)!.toStringAsFixed(2)} - \$${_getProductPriceMax(product)!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              else if (_getProductPriceMin(product) != null)
                                Text(
                                  'From \$${_getProductPriceMin(product)!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              SizedBox(height: 10),
                              Text("Country: ${_getProductCountry(product)}", style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                              Text("City: ${_getProductCity(product)}", style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Multi-select checkbox
            if (bookmarkProvider.isMultiSelectMode)
              Positioned(
                top: 8,
                right: 8,
                child: MultiSelectBookmarkButton(
                  itemType: 'product',
                  itemId: productId,
                  isSelected: isSelected,
                  onTap: () => bookmarkProvider.toggleItemSelection('product', productId),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showBulkBookmarkDialog(BuildContext context, BookmarkProvider bookmarkProvider) {
    final selectedItems = bookmarkProvider.getSelectedItemsData();
    if (selectedItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BulkBookmarkDialog(
          selectedItems: selectedItems,
          onConfirm: (vicId, notes) async {
            final success = await bookmarkProvider.bulkCreateBookmarks(
              vicId: vicId,
              notes: notes,
            );
            
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${selectedItems.length} items bookmarked successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to bookmark items: ${bookmarkProvider.error}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );
  }

  void _handleBulkDelete(BuildContext context, BookmarkProvider bookmarkProvider) {
    final selectedItems = bookmarkProvider.getSelectedItemsData();
    if (selectedItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1E1E1E),
          title: Text(
            'Remove Bookmarks',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to remove bookmarks for ${selectedItems.length} items?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await bookmarkProvider.bulkDeleteBookmarks();
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${selectedItems.length} bookmarks removed successfully'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove bookmarks: ${bookmarkProvider.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                'Remove',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _hasSelectedBookmarks(BookmarkProvider bookmarkProvider) {
    final selectedItems = bookmarkProvider.getSelectedItemsData();
    return selectedItems.any((item) => 
      bookmarkProvider.isItemBookmarked(item['itemType']!, item['itemId']!)
    );
  }

}

class ProductDetailModal extends StatelessWidget {
  final dynamic product;
  final bool isExternalProduct;

  const ProductDetailModal({
    Key? key,
    required this.product,
    required this.isExternalProduct,
  }) : super(key: key);

  // Helper methods to safely access product properties
  String _getProductName() {
    if (product == null) return 'Product Detail';
    
    try {
      if (isExternalProduct) {
        return product['name']?.toString() ?? 'Product Detail';
      } else {
        // Try both Map and ProductModel access patterns
        if (product is Map) {
          return product['name']?.toString() ?? 'Product Detail';
        } else {
          return product.name?.toString() ?? 'Product Detail';
        }
      }
    } catch (e) {
      return 'Product Detail';
    }
  }

  String _getProductDescription() {
    if (product == null) return 'No description available';
    
    try {
      if (isExternalProduct) {
        return product['description']?.toString() ?? 'No description available';
      } else {
        // Try both Map and ProductModel access patterns
        if (product is Map) {
          return product['description']?.toString() ?? 'No description available';
        } else {
          return product.description?.toString() ?? 'No description available';
        }
      }
    } catch (e) {
      return 'No description available';
    }
  }

  Map<String, dynamic> _getProductTags() {
    if (product == null) return {};
    
    try {
      if (isExternalProduct) {
        return Map<String, dynamic>.from(product['tags'] ?? {});
      } else {
        // Try both Map and ProductModel access patterns
        if (product is Map) {
          return Map<String, dynamic>.from(product['tags'] ?? {});
        } else {
          return Map<String, dynamic>.from(product.tags ?? {});
        }
      }
    } catch (e) {
      return {};
    }
  }

  List<dynamic> _getProductImages() {
    if (product == null) return [];
    
    try {
      if (isExternalProduct) {
        return List<dynamic>.from(product['rawData']?['imageUrls'] ?? []);
      } else {
        // Try both Map and ProductModel access patterns
        if (product is Map) {
          return List<dynamic>.from(product['images'] ?? []);
        } else {
          return List<dynamic>.from(product.images ?? []);
        }
      }
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Color(0xff292525),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                  // Bookmark button
                  _buildBookmarkButton(),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Row(
                children: [
                  // Left panel (1/3 width)
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            _getProductName(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          // Folder name button
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Color(0xff3A3A3A),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.folder, color: Colors.white, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Folder name',
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          // Description
                          Text(
                            _getProductDescription(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          // Tags section
                          Text(
                            'Tags',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (String key in _getProductTags().keys)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Color(0xff3A3A3A),
                                    border: Border.all(color: Colors.grey[600]!),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    _getProductTags()[key]?.toString() ?? '',
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                    // Right panel (2/3 width)
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Images grid
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[800],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: isExternalProduct
                                    ? _buildExternalProductImages()
                                    : _buildDatabaseProductImages(),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Download functionality
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[300],
                                    foregroundColor: Colors.black,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  child: Text('Download'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExternalProductImages() {
    final images = _getProductImages();
    return _buildImageGrid(images.map((url) => url.toString()).toList());
  }

  Widget _buildDatabaseProductImages() {
    final images = _getProductImages();
    if (images.isNotEmpty) {
      List<String> imageUrls = [];
      for (var img in images) {
        try {
          if (img is Map && img['signedUrl'] != null) {
            imageUrls.add(img['signedUrl'].toString());
          } else if (img.signedUrl != null) {
            imageUrls.add(img.signedUrl.toString());
          }
        } catch (e) {
          // Skip invalid image entries
          continue;
        }
      }
      return _buildImageGrid(imageUrls);
    }
    return _buildImageGrid([]);
  }

  Widget _buildImageGrid(List<String> imageUrls) {
    int imageCount = imageUrls.length;
    int displayCount;
    int placeholderCount = 0;

    // Determine how many images to show based on requirements
    if (imageCount >= 6) {
      displayCount = 6;
    } else if (imageCount >= 4) {
      displayCount = imageCount;
    } else if (imageCount > 0) {
      displayCount = 1;
      placeholderCount = 3;
    } else {
      displayCount = 0;
      placeholderCount = 4;
    }

    List<Widget> imageWidgets = [];

    // Add actual images
    for (int i = 0; i < displayCount && i < imageUrls.length; i++) {
      imageWidgets.add(_buildImageItem(imageUrls[i]));
    }

    // Add placeholder images
    for (int i = 0; i < placeholderCount; i++) {
      imageWidgets.add(_buildPlaceholderImage());
    }

    if (imageWidgets.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[800],
        child: Icon(Icons.image, color: Colors.white, size: 60),
      );
    }

    // Use GridView for responsive layout
    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: imageWidgets.length <= 2 ? 1 : 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: imageWidgets.length,
      itemBuilder: (context, index) => imageWidgets[index],
    );
  }

  Widget _buildImageItem(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[700],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[700],
              child: Icon(Icons.broken_image, color: Colors.white, size: 30),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[600],
        border: Border.all(color: Colors.grey[500]!, width: 1),
      ),
      child: Center(
        child: Icon(Icons.image_outlined, color: Colors.grey[400], size: 30),
      ),
    );
  }

  Widget _buildBookmarkButton() {
    // Get product ID safely
    String? productId;
    try {
      if (isExternalProduct) {
        productId = product['_id']?.toString() ?? product['id']?.toString();
      } else {
        if (product is Map) {
          productId = product['_id']?.toString() ?? product['id']?.toString();
        } else {
          productId = product.id?.toString() ?? product._id?.toString();
        }
      }
    } catch (e) {
      print('Error getting product ID: $e');
      return SizedBox.shrink();
    }

    if (productId == null) {
      return SizedBox.shrink();
    }

    return BookmarkButton(
      itemType: isExternalProduct ? 'externalProduct' : 'product',
      itemId: productId,
      color: Colors.white,
      activeColor: Colors.amber,
      size: 24,
    );
  }
}
  