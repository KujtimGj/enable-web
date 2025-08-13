import 'package:enable_web/core/dimensions.dart';
import 'package:enable_web/features/providers/userProvider.dart';
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

  @override
  void initState() {
    super.initState();
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
                Consumer<UserProvider>(
                  builder: (context, authProvider, child) {
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.go('/vics');
                            },
                            child: SvgPicture.asset('assets/icons/vics.svg'),
                          ),
                          SizedBox(height: 10),
                          SvgPicture.asset('assets/icons/diamond.svg'),
                          SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              context.go("/knowledgebase");
                            },
                            child: SvgPicture.asset('assets/icons/Icon.svg'),
                          ),
                          SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              showAccountOverlay(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: CircleAvatar(
                                maxRadius: 14,
                                minRadius: 14,
                                backgroundColor: Color(0xff574131),
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
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(width: 5),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: getHeight(context),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Text(
                              "Hi ${user?.name ?? 'User'}",
                              style: TextStyle(fontSize: 20),
                            ),
                            // User type indicator
                            Container(
                              margin: const EdgeInsets.only(top: 8, bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Text(
                                'Regular User',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              "How can I help you?",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey[600],
                              ),
                            ),
                            Consumer<ChatProvider>(
                              builder: (context, provider, _) {
                                final messages = provider.messages;

                                if (messages.isEmpty) {
                                  // fallback to static chat suggestions
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
                                            color: Colors.grey[300]!,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
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
                              },
                            ),
                          ],
                        ),
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
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: getHeight(context),
                    child: Consumer<ChatProvider>(
                      builder: (context, chatProvider, child) {
                        final products = chatProvider.externalProducts;

                        if (chatProvider.isLoading) {
                          return shimmerGrid();
                        }

                        if (products.isEmpty) {
                          return shimmerGrid();
                        }

                        return GridView.builder(
                          itemCount: products.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.5,
                                mainAxisSpacing: 15,
                                crossAxisSpacing: 15,
                              ),
                          itemBuilder: (context, index) {
                            final product = products[index];
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
}
