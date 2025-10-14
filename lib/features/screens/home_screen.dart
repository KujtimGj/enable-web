import 'package:enable_web/core/dimensions.dart';
import 'package:enable_web/features/components/widgets.dart';
import 'package:enable_web/features/components/vic_mention_field.dart';
import 'package:enable_web/features/components/clarifying_questions_widget.dart';
import 'package:enable_web/features/providers/userProvider.dart';
import 'package:enable_web/features/providers/productProvider.dart';
import 'package:enable_web/features/providers/vicProvider.dart';
import 'package:enable_web/features/components/bookmark_components.dart';
import 'package:enable_web/features/providers/bookmark_provider.dart';
import 'package:enable_web/features/components/product_detail_modal.dart';
import 'package:enable_web/features/components/vic_detail_modal.dart';
import 'package:enable_web/features/components/experience_detail_modal.dart';
import 'package:enable_web/features/components/dmc_detail_modal.dart';
import 'package:enable_web/features/components/service_provider_detail_modal.dart';
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
  final TextEditingController _chatController = TextEditingController();
  String _selectedSearchType = 'My Knowledge';

  void _handleFollowUpSubmitted(String followUpQuery) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    final userId = userProvider.user!.id;
    final agencyId = userProvider.user!.agencyId;
    final searchMode = _selectedSearchType == 'My Knowledge' ? 'my_knowledge' : 'external_search';

    await chatProvider.sendFollowUpResponse(
      userId: userId,
      agencyId: agencyId,
      followUpQuery: followUpQuery,
      searchMode: searchMode,
      context: context,
    );
  }

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

  // final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only fetch data if user is available
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user?.agencyId != null) {
        _fetchInitialData();
      }
    });
  }

  void _fetchInitialData() {
    // Clear any previous chat state to show conversations properly
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.startNewConversation();
    
    // Fetch products, conversations, and VICs in parallel for better performance
    Future.wait([
      _fetchProducts(),
      _fetchConversations(),
      _fetchVICs(),
    ]).catchError((error) {
      print('Error fetching initial data: $error');
      return <void>[];
    });
  }

  Future<void> _fetchProducts() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      if (userProvider.user?.agencyId != null) {
        // Use optimized endpoint for home screen - only fetch 20 products
        await productProvider.fetchProductsLimitedByAgencyId(userProvider.user!.agencyId);
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> _fetchConversations() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      if (userProvider.user?.id != null) {
        // Use optimized endpoint for home screen - only fetch 3 latest conversations
        await chatProvider.fetchLastConversationsByUserId(userProvider.user!.id);
      }
    } catch (e) {
      print('Error fetching conversations: $e');
    }
  }

  Future<void> _fetchVICs() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final vicProvider = Provider.of<VICProvider>(context, listen: false);

      if (userProvider.user?.agencyId != null) {
        await vicProvider.fetchVICsByAgencyId(userProvider.user!.agencyId);
      }
    } catch (e) {
      print('Error fetching VICs: $e');
    }
  }

  void _showProductDetailModal(BuildContext context, dynamic product, bool isExternalProduct,) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ProductDetailModal(
          product: product,
          isExternalProduct: isExternalProduct,
        );
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

  bool isHovered = false;

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
          return category.isNotEmpty
              ? category[0].toUpperCase() + category.substring(1)
              : '';
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
        return country.isNotEmpty
            ? country[0].toUpperCase() + country.substring(1)
            : '';
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
              if (chatProvider.conversationId != null ||
                  chatProvider.messages.isNotEmpty) {
                return customButton(() => _startNewConversation(context));
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
                                    final structuredSummary =
                                        provider.structuredSummary;
                                    

                                    // Show error message if there's an error
                                    if (error != null) {
                                      return Container(
                                        width: getWidth(context),
                                        padding: EdgeInsets.all(16),
                                        margin: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          border: Border.all(
                                            color: Colors.red[200]!,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red[600],
                                                  size: 20,
                                                ),
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
                                                style: TextStyle(
                                                  color: Colors.red[600],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    // Show conversations when available and no active chat session
                                    if (messages.isEmpty && structuredSummary == null) {
                                      // Show loading state
                                      if (provider.isLoadingConversations) {
                                        return ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          itemCount: 3,
                                          itemBuilder: (context, index) {
                                            return Container(
                                              width: getWidth(context),
                                              padding: EdgeInsets.symmetric(
                                                vertical: 15,
                                                horizontal: 10,
                                              ),
                                              margin: EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Color(0xff292525),
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                color: Color(0xff1A1818),
                                              ),
                                              child: Shimmer.fromColors(
                                                baseColor: Color(0xff292525),
                                                highlightColor: Color(
                                                  0xff3a3a3a,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      height: 30,
                                                      width: 30,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              5,
                                                            ),
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
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          itemCount:
                                              provider.conversations.length,
                                          itemBuilder: (context, index) {
                                            final conversation =
                                                provider.conversations[index];
                                            final conversationName =
                                                conversation['messages'][0]['content'] ??
                                                'Conversation ${index + 1}';
                                            return Container(
                                              width: getWidth(context),
                                              padding: EdgeInsets.symmetric(
                                                vertical: 15,
                                                horizontal: 10,
                                              ),
                                              margin: EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Color(0xff292525),
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                color: Color(0xff1A1818),
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
                                                          BorderRadius.circular(
                                                            5,
                                                          ),
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
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 1,
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
                                            padding: EdgeInsets.symmetric(
                                              vertical: 15,
                                              horizontal: 10,
                                            ),
                                            margin: EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Color(0xff292525),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              color: Color(0xff1A1818),
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
                                                        BorderRadius.circular(
                                                          5,
                                                        ),
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

                                          return EnhancedMessageBubble(
                                            message: msg,
                                            onFollowUpSubmitted: _handleFollowUpSubmitted,
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
                                child: VICMentionField(
                                  controller: _chatController,
                                  onSubmitted: (value) async {
                                    final userProvider =
                                        Provider.of<UserProvider>(
                                          context,
                                          listen: false,
                                        );
                                    final chatProvider =
                                        Provider.of<ChatProvider>(
                                          context,
                                          listen: false,
                                        );
 
                                    final userId = userProvider.user!.id;
                                    final agencyId =
                                        userProvider.user!.agencyId;

                                    if (value.trim().isEmpty) return;

                                    chatProvider.addUserMessage(value.trim());
                                    chatProvider.addAgentPlaceholder();

                                    _chatController.clear();

                                    // Determine search mode based on user selection
                                    final searchMode =
                                        _selectedSearchType == 'My Knowledge'
                                            ? 'my_knowledge'
                                            : 'external_search';

                                    await chatProvider.sendIntelligentQuery(
                                      userId: userId,
                                      agencyId: agencyId,
                                      query: value.trim(),
                                      searchMode: searchMode,
                                      existingConversationId:
                                      chatProvider.conversationId,
                                      context: context,
                                    );
                                  },
                                  hintText: 'Ask Enable',
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SvgPicture.asset(
                                      'assets/icons/star-05.svg',
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 160,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xff3a3132),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[700]!),
                                ),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _selectedSearchType,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  menuChildren: [
                                    MenuItemButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedSearchType = 'My Knowledge';
                                        });
                                      },
                                      child: const Text('My Knowledge'),
                                    ),
                                    MenuItemButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedSearchType =
                                              'External Search';
                                        });
                                      },
                                      child: const Text('External Search'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
                      builder: (
                        context,
                        chatProvider,
                        productProvider,
                        bookmarkProvider,
                        child,
                      ) {
                        final externalProducts = chatProvider.externalProducts;
                        final vics = chatProvider.vics;
                        final experiences = chatProvider.experiences;
                        final dmcs = chatProvider.dmcs;
                        final serviceProviders = chatProvider.serviceProviders;
                        final dbProducts = productProvider.products;

                        // Prepare items for multi-select
                        final allItems = <Map<String, String>>[];
                        for (final product in externalProducts) {
                          final productId =
                              product['_id']?.toString() ??
                              product['id']?.toString();
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
                        for (final vic in vics) {
                          final vicId = vic['_id']?.toString() ?? vic['id']?.toString();
                          if (vicId != null) {
                            allItems.add({
                              'itemType': 'vic',
                              'itemId': vicId,
                            });
                          }
                        }
                        for (final experience in experiences) {
                          final experienceId = experience['_id']?.toString() ?? experience['id']?.toString();
                          if (experienceId != null) {
                            allItems.add({
                              'itemType': 'experience',
                              'itemId': experienceId,
                            });
                          }
                        }
                        for (final dmc in dmcs) {
                          final dmcId = dmc['_id']?.toString() ?? dmc['id']?.toString();
                          if (dmcId != null) {
                            allItems.add({
                              'itemType': 'dmc',
                              'itemId': dmcId,
                            });
                          }
                        }
                        for (final serviceProvider in serviceProviders) {
                          final serviceProviderId = serviceProvider['_id']?.toString() ?? serviceProvider['id']?.toString();
                          if (serviceProviderId != null) {
                            allItems.add({
                              'itemType': 'serviceProvider',
                              'itemId': serviceProviderId,
                            });
                          }
                        }

                        return Column(
                          children: [
                            // Multi-select toolbar
                            MultiSelectToolbar(
                              selectedCount: bookmarkProvider.selectedCount,
                              isMultiSelectMode:
                                  bookmarkProvider.isMultiSelectMode,
                              onToggleMultiSelect:
                                  () =>
                                      bookmarkProvider.toggleMultiSelectMode(),
                              onSelectAll:
                                  () =>
                                      bookmarkProvider.selectAllItems(allItems),
                              onClearSelection:
                                  () => bookmarkProvider.clearSelection(),
                              onBulkBookmark:
                                  () => _showBulkBookmarkDialog(
                                    context,
                                    bookmarkProvider,
                                  ),
                              onBulkDelete:
                                  () => _handleBulkDelete(
                                    context,
                                    bookmarkProvider,
                                  ),
                              hasBookmarks: _hasSelectedBookmarks(
                                bookmarkProvider,
                              ),
                            ),

                            // Grid content
                            Expanded(
                              child: _buildGridContent(
                                chatProvider,
                                productProvider,
                                bookmarkProvider,
                                externalProducts,
                                vics,
                                experiences,
                                dmcs,
                                serviceProviders,
                                dbProducts,
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


  Widget _buildRandomImageItem(List<dynamic> images, String productId) {
    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.image, color: Colors.white, size: 20),
      );
    }

    // Use productId hash to generate a stable "random" index
    final hash = productId.hashCode;
    final stableIndex = hash.abs() % images.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        images[stableIndex],
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
            child: Icon(Icons.image, color: Colors.white, size: 20),
          );
        },
      ),
    );
  }


  Widget _buildRandomDatabaseImageItem(List<dynamic> images, String productId) {
    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.image, color: Colors.white, size: 20),
      );
    }

    // Use productId hash to generate a stable "random" index
    final hash = productId.hashCode;
    final stableIndex = hash.abs() % images.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        images[stableIndex].signedUrl,
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
            child: Icon(Icons.image, color: Colors.white, size: 20),
          );
        },
      ),
    );
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
      return SizedBox.shrink();
    }

    if (productId == null) {
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

  Widget _buildGridContent(ChatProvider chatProvider, ProductProvider productProvider, BookmarkProvider bookmarkProvider, List<dynamic> externalProducts, List<dynamic> vics, List<dynamic> experiences, List<dynamic> dmcs, List<dynamic> serviceProviders, List<dynamic> dbProducts,) {
    // Show loading state if any provider is loading
    if (chatProvider.isLoading || productProvider.isLoading) {
      return shimmerGrid();
    }

    // If experiences are present, always show them (optionally with the client on top if provided)
    if (experiences.isNotEmpty) {
      if (vics.isNotEmpty) {
        final singleVic = vics.take(1).toList();
        return ListView(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                'Client',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            _buildVicsGrid(singleVic, bookmarkProvider),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                'Past trips',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            _buildExperiencesGrid(experiences, bookmarkProvider),
          ],
        );
      }
      return _buildExperiencesGrid(experiences, bookmarkProvider);
    }

    // Otherwise, prioritize different data types based on what's available
    if (vics.isNotEmpty) {
      return _buildVicsGrid(vics, bookmarkProvider);
    }

    if (dmcs.isNotEmpty) {
      return _buildDMCsGrid(dmcs, bookmarkProvider);
    }

    if (serviceProviders.isNotEmpty) {
      return _buildServiceProvidersGrid(serviceProviders, bookmarkProvider);
    }

    if (externalProducts.isNotEmpty) {
      return _buildExternalProductsGrid(externalProducts, bookmarkProvider);
    }

    if (dbProducts.isNotEmpty) {
      return _buildDatabaseProductsGrid(dbProducts, bookmarkProvider);
    }

    // Show empty state instead of shimmer when no data
    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[600],
          ),
          SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try asking a question to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalProductsGrid(List<dynamic> externalProducts, BookmarkProvider bookmarkProvider,) {
    // Limit external products for better performance
    final limitedExternalProducts = externalProducts.take(10).toList();
    
    return GridView.builder(
      itemCount: limitedExternalProducts.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      itemBuilder: (context, index) {
        final product = limitedExternalProducts[index];
        final productId =
            product['_id']?.toString() ?? product['id']?.toString();
        final isSelected = bookmarkProvider.isItemSelected(
          'externalProduct',
          productId ?? '',
        );

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
          images =
              (product['rawData']?['imageUrls'] ?? [])
                  .map((url) => url.toString())
                  .toList()
                  .cast<String>();
        }

        return Stack(
          children: [
            InkWell(
              onTap: () {
                if (bookmarkProvider.isMultiSelectMode) {
                  bookmarkProvider.toggleItemSelection(
                    'externalProduct',
                    productId ?? '',
                  );
                } else {
                  _showProductDetailModal(
                    context, 
                    product,
                    product['images'] == null || product['images'].isEmpty,
                  );
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
                    // Single random image on the left side
                    Expanded(
                      flex: 1,
                      child: images.isNotEmpty
                          ? _buildRandomImageItem(images, productId ?? '')
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
                  onTap:
                      () => bookmarkProvider.toggleItemSelection(
                        'externalProduct',
                        productId ?? '',
                      ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDatabaseProductsGrid(List<dynamic> dbProducts, BookmarkProvider bookmarkProvider) {
    // Limit items for better performance
    final limitedProducts = dbProducts.take(20).toList();
    
    return GridView.builder(
      itemCount: limitedProducts.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      itemBuilder: (context, index) {
        final product = limitedProducts[index];
        final images = product.images;
        final productId = product.id.toString();
        final isSelected = bookmarkProvider.isItemSelected(
          'product',
          productId,
        );

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
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: images != null && images.isNotEmpty
                            ? _buildRandomDatabaseImageItem(images, productId)
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                              if (_getProductPriceMin(product) != null ||
                                  _getProductPriceMax(product) != null)
                                SizedBox(height: 2),
                              if (_getProductPriceMin(product) != null &&
                                  _getProductPriceMax(product) != null)
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
                              Text(
                                "Country: ${_getProductCountry(product)}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                              Text(
                                "City: ${_getProductCity(product)}",
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
                  onTap:
                      () => bookmarkProvider.toggleItemSelection(
                        'product',
                        productId,
                      ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildVicsGrid(List<dynamic> vics, BookmarkProvider bookmarkProvider) {
    // Limit VICs for better performance
    final limitedVics = vics.take(10).toList();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: limitedVics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      itemBuilder: (context, index) {
        final vic = limitedVics[index];
        final vicId = vic['_id']?.toString() ?? vic['id']?.toString() ?? '';
        final isSelected = bookmarkProvider.isItemSelected('vic', vicId);

        return Stack(
          children: [
            InkWell(
              onTap: () {
                if (bookmarkProvider.isMultiSelectMode) {
                  bookmarkProvider.toggleItemSelection('vic', vicId);
                } else {
                  _showVicDetailModal(context, vic);
                }
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF181616),
                  border: Border.all(
                    width: isSelected ? 2 : 0.5,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // VIC Avatar and basic info
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xff574435),
                          ),
                          child: Center(
                            child: Text(
                              _getVicInitials(vic),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getVicName(vic),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                _getVicEmail(vic),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Bookmark button for VICs
                        if (!bookmarkProvider.isMultiSelectMode)
                          _buildVicBookmarkButton(vic),
                      ],
                    ),
                    SizedBox(height: 12),
                    // VIC Details
                    if (_getVicPhone(vic).isNotEmpty)
                      _buildVicDetailRow(Icons.phone, _getVicPhone(vic)),
                    if (_getVicNationality(vic).isNotEmpty)
                      _buildVicDetailRow(Icons.flag, _getVicNationality(vic)),
                    if (_getVicSummary(vic).isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'Summary',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[300],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _getVicSummary(vic),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
                  itemType: 'vic',
                  itemId: vicId,
                  isSelected: isSelected,
                  onTap: () => bookmarkProvider.toggleItemSelection('vic', vicId),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildExperiencesGrid(List<dynamic> experiences, BookmarkProvider bookmarkProvider,) {
    // Limit experiences for better performance
    final limitedExperiences = experiences.take(10).toList();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: limitedExperiences.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      itemBuilder: (context, index) {
        final experience = limitedExperiences[index];
        final experienceId = experience['_id']?.toString() ?? experience['id']?.toString() ?? '';
        final isSelected = bookmarkProvider.isItemSelected('experience', experienceId);

        // Get images for the experience
        List<String> images = [];
        try {
          if (experience['images'] != null) {
            // Images are processed below in the main loop
          }
          
          if (experience['images'] != null && experience['images'].isNotEmpty) {
            for (var img in experience['images']) {
              if (img is Map && img['signedUrl'] != null && img['signedUrl'].toString().isNotEmpty) {
                images.add(img['signedUrl'].toString());
              } else if (img is Map && img['imageUrl'] != null && img['imageUrl'].toString().isNotEmpty) {
                // Fallback to imageUrl if signedUrl is not available
                images.add(img['imageUrl'].toString());
              }
            }
          } else {
            print('No images found for experience - images field is null or empty');
          }
        } catch (e) {
          print('Error extracting images: $e');
        }

        return Stack(
          children: [
            InkWell(
              onTap: () {
                if (bookmarkProvider.isMultiSelectMode) {
                  bookmarkProvider.toggleItemSelection('experience', experienceId);
                } else {
                  _showExperienceDetailModal(context, experience);
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
                    // Single image on the left side
                    Expanded(
                      flex: 1,
                      child: images.isNotEmpty
                          ? _buildRandomImageItem(images, experienceId)
                          : Container(
                              width: double.infinity,
                              height: double.infinity,
                          decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.flight_takeoff,
                            color: Colors.white,
                                size: 40,
                          ),
                        ),
                    ),
                    // Experience details on the right side
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
                                _getExperienceDestination(experience),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                    maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Bookmark button for experiences
                        if (!bookmarkProvider.isMultiSelectMode)
                          _buildExperienceBookmarkButton(experience),
                      ],
                    ),
                            SizedBox(height: 4),
                      Text(
                              _getExperienceCountry(experience),
                        style: TextStyle(
                          fontSize: 12,
                                color: Colors.grey[400],
                        ),
                      ),
                      SizedBox(height: 4),
                            if (_getExperienceDates(experience).isNotEmpty)
                      Text(
                                _getExperienceDates(experience),
                        style: TextStyle(
                          fontSize: 11,
                                  color: Colors.grey[500],
                        ),
                                maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                              ),
                            SizedBox(height: 4),
                            Text(
                              _getExperienceStatus(experience),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                            // Show itinerary count if available
                            if (_getExperienceItineraryCount(experience) > 0)
                              Row(
                                children: [
                                  Icon(Icons.timeline, size: 12, color: Colors.orange[400]),
                                  SizedBox(width: 4),
                                  Text(
                                    '${_getExperienceItineraryCount(experience)} items',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange[400],
                                      fontWeight: FontWeight.w500,
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
            ),
            // Multi-select checkbox
            if (bookmarkProvider.isMultiSelectMode)
              Positioned(
                top: 8,
                right: 8,
                child: MultiSelectBookmarkButton(
                  itemType: 'experience',
                  itemId: experienceId,
                  isSelected: isSelected,
                  onTap: () => bookmarkProvider.toggleItemSelection('experience', experienceId),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDMCsGrid(List<dynamic> dmcs, BookmarkProvider bookmarkProvider,) {
    // Limit DMCs for better performance
    final limitedDMCs = dmcs.take(10).toList();
    
    return GridView.builder(
      itemCount: limitedDMCs.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      itemBuilder: (context, index) {
        final dmc = limitedDMCs[index];
        final dmcId = dmc['_id']?.toString() ?? dmc['id']?.toString() ?? '';
        final isSelected = bookmarkProvider.isItemSelected('dmc', dmcId);

        return Stack(
          children: [
            InkWell(
              onTap: () {
                if (bookmarkProvider.isMultiSelectMode) {
                  bookmarkProvider.toggleItemSelection('dmc', dmcId);
                } else {
                  _showDMCDetailModal(context, dmc);
                }
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF181616),
                  border: Border.all(
                    width: isSelected ? 2 : 0.5,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DMC Header
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(0xff574435),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.business,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getDMCBusinessName(dmc),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                _getDMCLocation(dmc),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Bookmark button for DMCs
                        if (!bookmarkProvider.isMultiSelectMode)
                          _buildDMCBookmarkButton(dmc),
                      ],
                    ),
                    SizedBox(height: 12),
                    // DMC Details
                    if (_getDMCDescription(dmc).isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[300],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _getDMCDescription(dmc),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
                  itemType: 'dmc',
                  itemId: dmcId,
                  isSelected: isSelected,
                  onTap: () => bookmarkProvider.toggleItemSelection('dmc', dmcId),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildServiceProvidersGrid(List<dynamic> serviceProviders, BookmarkProvider bookmarkProvider,) {
    // Limit service providers for better performance
    final limitedServiceProviders = serviceProviders.take(10).toList();
    
    return GridView.builder(
      itemCount: limitedServiceProviders.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      itemBuilder: (context, index) {
        final serviceProvider = limitedServiceProviders[index];
        final serviceProviderId = serviceProvider['_id']?.toString() ?? serviceProvider['id']?.toString() ?? '';
        final isSelected = bookmarkProvider.isItemSelected('serviceProvider', serviceProviderId);

        return Stack(
          children: [
            InkWell(
              onTap: () {
                if (bookmarkProvider.isMultiSelectMode) {
                  bookmarkProvider.toggleItemSelection('serviceProvider', serviceProviderId);
                } else {
                  _showServiceProviderDetailModal(context, serviceProvider);
                }
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF181616),
                  border: Border.all(
                    width: isSelected ? 2 : 0.5,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Provider Header
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(0xff574435),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.support_agent,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getServiceProviderCompanyName(serviceProvider),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                _getServiceProviderCountry(serviceProvider),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Bookmark button for service providers
                        if (!bookmarkProvider.isMultiSelectMode)
                          _buildServiceProviderBookmarkButton(serviceProvider),
                      ],
                    ),
                    SizedBox(height: 12),
                    // Service Provider Details
                    if (_getServiceProviderExpertise(serviceProvider).isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'Expertise',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[300],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _getServiceProviderExpertise(serviceProvider),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
                  itemType: 'serviceProvider',
                  itemId: serviceProviderId,
                  isSelected: isSelected,
                  onTap: () => bookmarkProvider.toggleItemSelection('serviceProvider', serviceProviderId),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildVicDetailRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[500]),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[400],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVicBookmarkButton(dynamic vic) {
    String? vicId;
    try {
      vicId = vic['_id']?.toString() ?? vic['id']?.toString();
    } catch (e) {
      print('Error getting VIC ID: $e');
      return SizedBox.shrink();
    }

    if (vicId == null) {
      return SizedBox.shrink();
    }

    return BookmarkButton(
      itemType: 'vic',
      itemId: vicId,
      color: Colors.white70,
      activeColor: Colors.amber,
      size: 20,
    );
  }

  // Helper methods for VIC data
  String _getVicName(dynamic vic) {
    if (vic == null) return 'Unknown Client';
    try {
      return vic['fullName']?.toString() ?? 'Unknown Client';
    } catch (e) {
      return 'Unknown Client';
    }
  }

  String _getVicEmail(dynamic vic) {
    if (vic == null) return '';
    try {
      return vic['email']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  String _getVicPhone(dynamic vic) {
    if (vic == null) return '';
    try {
      return vic['phone']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  String _getVicNationality(dynamic vic) {
    if (vic == null) return '';
    try {
      return vic['nationality']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  String _getVicSummary(dynamic vic) {
    if (vic == null) return '';
    try {
      return vic['summary']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  String _getVicInitials(dynamic vic) {
    final name = _getVicName(vic);
    if (name.isEmpty) return 'U';
    
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  void _showVicDetailModal(BuildContext context, dynamic vic) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return VICDetailModal(vic: vic);
      },
    );
  }

  // Experience helper methods
  String _getExperienceDestination(dynamic experience) {
    try {
      return experience['destination']?.toString() ?? 'Unknown Destination';
    } catch (e) {
      return 'Unknown Destination';
    }
  }

  String _getExperienceCountry(dynamic experience) {
    try {
      return experience['country']?.toString() ?? 'Unknown Country';
    } catch (e) {
      return 'Unknown Country';
    }
  }

  String _getExperienceDates(dynamic experience) {
    try {
      final startDate = experience['startDate'];
      final endDate = experience['endDate'];
      
      if (startDate != null && endDate != null) {
        DateTime? start, end;
        
        // Handle MongoDB date format
        if (startDate is Map && startDate['\$date'] != null) {
          start = DateTime.tryParse(startDate['\$date'].toString());
        } else if (startDate is String) {
          start = DateTime.tryParse(startDate);
        }
        
        if (endDate is Map && endDate['\$date'] != null) {
          end = DateTime.tryParse(endDate['\$date'].toString());
        } else if (endDate is String) {
          end = DateTime.tryParse(endDate);
        }
        
        if (start != null && end != null) {
          return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
        }
      }
      
      return '';
    } catch (e) {
      return '';
    }
  }

  String _getExperienceStatus(dynamic experience) {
    try {
      return experience['status']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }


  int _getExperienceItineraryCount(dynamic experience) {
    try {
      final itinerary = experience['itinerary'] ?? experience['itineraryItems'];
      if (itinerary is List) {
        return itinerary.length;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }  


  Widget _buildExperienceBookmarkButton(dynamic experience) {
    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, child) {
        final experienceId = experience['_id']?.toString() ?? experience['id']?.toString() ?? '';
        final isBookmarked = bookmarkProvider.isItemBookmarked('experience', experienceId);
        
        return IconButton(
          onPressed: () {
            bookmarkProvider.toggleBookmark(
              itemType: 'experience',
              itemId: experienceId,
            );
          },
          icon: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: isBookmarked ? Colors.amber : Colors.grey[400],
            size: 20,
          ),
        );
      },
    );
  }

  void _showExperienceDetailModal(BuildContext context, dynamic experience) async {
    // Open directly with available data to avoid fetch mismatch issues
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ExperienceDetailModal(experience: experience);
      },
    );
  }
  

  // DMC helper methods
  String _getDMCBusinessName(dynamic dmc) {
    try {
      return dmc['businessName']?.toString() ?? 'Unknown Business';
    } catch (e) {
      return 'Unknown Business';
    }
  }

  String _getDMCLocation(dynamic dmc) {
    try {
      return dmc['location']?.toString() ?? 'Unknown Location';
    } catch (e) {
      return 'Unknown Location';
    }
  }
  
  String _getDMCDescription(dynamic dmc) {
    try {
      return dmc['description']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  Widget _buildDMCBookmarkButton(dynamic dmc) {
    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, child) {
        final dmcId = dmc['_id']?.toString() ?? dmc['id']?.toString() ?? '';
        final isBookmarked = bookmarkProvider.isItemBookmarked('dmc', dmcId);
        
        return IconButton(
          onPressed: () {
            bookmarkProvider.toggleBookmark(
              itemType: 'dmc',
              itemId: dmcId,
            );
          },
          icon: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: isBookmarked ? Colors.amber : Colors.grey[400],
            size: 20,
          ),
        );
      },
    );
  }

  void _showDMCDetailModal(BuildContext context, dynamic dmc) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return DMCDetailModal(dmc: dmc);
      },
    );
  }

  // Service Provider helper methods
  String _getServiceProviderCompanyName(dynamic serviceProvider) {
    try {
      return serviceProvider['companyName']?.toString() ?? 'Unknown Company';
    } catch (e) {
      return 'Unknown Company';
    }
  }

  String _getServiceProviderCountry(dynamic serviceProvider) {
    try {
      return serviceProvider['countryOfOperation']?.toString() ?? 'Unknown Country';
    } catch (e) {
      return 'Unknown Country';
    }
  }

  String _getServiceProviderExpertise(dynamic serviceProvider) {
    try {
      final expertise = serviceProvider['productExpertise'];
      if (expertise is List) {
        return expertise.join(', ');
      }
      return expertise?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  Widget _buildServiceProviderBookmarkButton(dynamic serviceProvider) {
    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, child) {
        final serviceProviderId = serviceProvider['_id']?.toString() ?? serviceProvider['id']?.toString() ?? '';
        final isBookmarked = bookmarkProvider.isItemBookmarked('serviceProvider', serviceProviderId);
        
        return IconButton(
          onPressed: () {
            bookmarkProvider.toggleBookmark(
              itemType: 'serviceProvider',
              itemId: serviceProviderId,
            );
          },
          icon: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: isBookmarked ? Colors.amber : Colors.grey[400],
            size: 20,
          ),
        );
      },
    );
  }

  void _showServiceProviderDetailModal(BuildContext context, dynamic serviceProvider) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ServiceProviderDetailModal(serviceProvider: serviceProvider);
      },
    );
  }

  void _showBulkBookmarkDialog(BuildContext context, BookmarkProvider bookmarkProvider,) {
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
                  content: Text(
                    '${selectedItems.length} items bookmarked successfully',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to bookmark items: ${bookmarkProvider.error}',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );
  }

  void _handleBulkDelete(BuildContext context, BookmarkProvider bookmarkProvider,) {
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
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await bookmarkProvider.bulkDeleteBookmarks();

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${selectedItems.length} bookmarks removed successfully',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to remove bookmarks: ${bookmarkProvider.error}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  bool _hasSelectedBookmarks(BookmarkProvider bookmarkProvider) {
    final selectedItems = bookmarkProvider.getSelectedItemsData();
    return selectedItems.any(
      (item) =>
          bookmarkProvider.isItemBookmarked(item['itemType']!, item['itemId']!),
    );
  }
}
