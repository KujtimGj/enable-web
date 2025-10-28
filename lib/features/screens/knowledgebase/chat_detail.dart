import 'package:enable_web/core/dimensions.dart';
import 'package:enable_web/features/components/responsive_scaffold.dart';
import 'package:enable_web/features/components/clarifying_questions_widget.dart';
import 'package:enable_web/features/providers/agentProvider.dart';
import 'package:enable_web/features/providers/userProvider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../components/widgets.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String conversationName;

  const ChatDetailScreen({
    super.key, 
    required this.conversationId,
    required this.conversationName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversationMessages();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadConversationMessages() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Ensure conversations are loaded first
    if (userProvider.user?.agencyId != null) {
      await chatProvider.fetchConversations(userProvider.user!.agencyId);
    }
    
    // Then load the specific conversation messages
    chatProvider.loadConversationMessages(widget.conversationId);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleFollowUpSubmitted(String followUpQuery) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    final userId = userProvider.user!.id;
    final agencyId = userProvider.user!.agencyId;
    final searchMode = 'my_knowledge'; // Default to my knowledge for follow-ups

    await chatProvider.sendFollowUpResponse(
      userId: userId,
      agencyId: agencyId,
      followUpQuery: followUpQuery,
      searchMode: searchMode,
      context: context,
    );

    // Scroll to bottom after follow-up
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return ResponsiveScaffold(
          appBar: AppBar(
            toolbarHeight: 60,
            automaticallyImplyLeading: false,
            leadingWidth: 200,
            centerTitle: true,
            title: Text(
              widget.conversationName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            leading: GestureDetector(
              onTap: () => context.go('/knowledgebase/chats'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset("assets/icons/home.svg")
                ],
              ),
            ),
            actions: [customButton(() => context.go("/"))],
          ),
          body: Column(
            children: [
              Expanded(
                child: _buildMessagesList(chatProvider),
              ),
              if (chatProvider.isLoading) _buildLoadingIndicator(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessagesList(ChatProvider chatProvider) {
    if (chatProvider.isLoadingMessages) {
      return _buildLoadingMessages();
    }

    if (chatProvider.error != null) {
      return _buildErrorState(chatProvider);
    }

    if (chatProvider.messages.isEmpty) {
      return _buildEmptyState();
    }

    // Auto-scroll to bottom when messages load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: chatProvider.messages.length,
      itemBuilder: (context, index) {
        final message = chatProvider.messages[index];

        return EnhancedMessageBubble(
          message: message,
          onFollowUpSubmitted: _handleFollowUpSubmitted,
        );
      },
    );
  }


  Widget _buildLoadingMessages() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        final isUser = index % 2 == 0;
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: getWidth(context) * 0.5,
            ),
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUser ? Color(0xff2D5A87) : Color(0xff1A1818),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUser ? Color(0xff3A6B9A) : Color(0xff292525),
                width: 1,
              ),
            ),
            child: Shimmer.fromColors(
              baseColor: isUser ? Color(0xff3A6B9A) : Color(0xff292525),
              highlightColor: isUser ? Color(0xff4A7BAA) : Color(0xff3A3A3A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  SizedBox(height: 4),
                  Container(
                    height: 14,
                    width: getWidth(context) * 0.4,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(ChatProvider chatProvider) {
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
            'Failed to load messages',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          SelectableText(
            chatProvider.error!,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadConversationMessages(),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'No messages in this conversation',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This conversation appears to be empty',
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

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Loading messages...',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
