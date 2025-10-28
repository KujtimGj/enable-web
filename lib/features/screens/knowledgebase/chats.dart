import 'package:enable_web/core/dimensions.dart';
import 'package:enable_web/features/components/responsive_scaffold.dart';
import 'package:enable_web/features/providers/agentProvider.dart';
import 'package:enable_web/features/providers/userProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../components/widgets.dart';

class ChatsList extends StatefulWidget {
  const ChatsList({super.key});

  @override
  State<ChatsList> createState() => _ChatsListState();
}

class _ChatsListState extends State<ChatsList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchConversations();
    });
  }

  void _fetchConversations() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (userProvider.user?.agencyId != null) {
      print('ChatsList: Fetching conversations for agency: ${userProvider.user!.agencyId}');
      chatProvider.fetchConversations(userProvider.user!.agencyId); // Fetch all conversations
    } else {
      print('ChatsList: No agency ID found, cannot fetch conversations');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return ResponsiveScaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => context.go('/home'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset("assets/icons/home.svg")
            ],
          ),
        ),
        actions: [customButton((){context.go("/");})],
      ),
      body: Row(
        children: [
          bottomLeftBar(),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 15),
                  ResponsiveContainer(
                    maxWidth: getWidth(context)*0.3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chatProvider.isLoadingConversations 
                              ? "Loading conversations..." 
                              : "${chatProvider.conversations.length} Conversations in Enable",
                          textAlign: TextAlign.start,
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          decoration: InputDecoration(
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SvgPicture.asset(
                                'assets/icons/star-05.svg',
                              ),
                            ),
                            hintText: 'Search for conversations',
                            hintStyle: TextStyle(color: Colors.white),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ResponsiveContainer(
                    maxWidth: getWidth(context)*0.3,
                    child: _buildConversationsList(chatProvider),
                  )
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

  Widget _buildConversationsList(ChatProvider chatProvider) {
    // Show loading state
    if (chatProvider.isLoadingConversations) {
      return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: 5),
        itemCount: 5, // Show 5 loading placeholders
        itemBuilder: (context, index) {
          return Container(
            width: getWidth(context)*0.3,
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            margin: EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: Color(0xff1A1818),
              border: Border.all(color: Color(0xff292525)),
              borderRadius: BorderRadius.circular(5),
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
                    width: 150,
                    color: Colors.white,
                  ),
                  SizedBox(height: 5),
                  Container(
                    height: 12,
                    width: 200,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // Show error state
    if (chatProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Failed to load conversations',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              chatProvider.error!,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchConversations(),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show conversations
    if (chatProvider.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Colors.grey[400],
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start a new conversation to see it here',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show actual conversations
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 5),
      itemCount: chatProvider.conversations.length,
      itemBuilder: (context, index) {
        final conversation = chatProvider.conversations[index];
        final conversationName = conversation['name'] ?? 'Conversation ${index + 1}';
        final first = conversation['messages']?.isNotEmpty == true
            ? conversation['messages'].first['content'] ?? 'No messages'
            : 'No messages';

        return Container(
          margin: EdgeInsets.symmetric(vertical: 5),
          child: _HoverableChatCard(
            onTap: () {
              // Navigate to chat detail screen with conversation name
              final encodedName = Uri.encodeComponent(conversationName);
              context.go('/knowledgebase/chats/${conversation['_id']}?name=$encodedName');
            },
            child: Container(
              width: getWidth(context)*0.3,
              height: 88,
              padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: Color(0xff292525),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(width: 1, color: Color(0xff292525)),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/chat.svg',
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  first,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }
}

class _HoverableChatCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HoverableChatCard({
    required this.onTap,
    required this.child,
  });

  @override
  State<_HoverableChatCard> createState() => _HoverableChatCardState();
}

class _HoverableChatCardState extends State<_HoverableChatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: _isHovered ? Color(0xFF211E1E) : Color(0xFF181616),
            border: Border.all(color: _isHovered ? Color(0xFF665B5B) : Color(0xff292525)),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
