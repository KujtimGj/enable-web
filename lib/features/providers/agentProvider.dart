import 'package:enable_web/features/controllers/searchModeController.dart';
import 'package:enable_web/features/controllers/conversationController.dart';
import 'package:flutter/foundation.dart';

class ChatProvider extends ChangeNotifier {
  final SearchModeController _searchModeController = SearchModeController();
  final ConversationController _conversationController = ConversationController();

  String? _message;
  List<dynamic> _externalProducts = [];
  bool _isLoading = false;
  String? _error;
  String? _conversationId;
  String? _structuredSummary;
  List<Map<String, dynamic>> _conversations = [];
  Map<String, dynamic>? _currentConversation;
  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;

  // Getters
  String? get message => _message;
  List<dynamic> get externalProducts => _externalProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get conversationId => _conversationId;
  String? get structuredSummary => _structuredSummary;
  List<Map<String, dynamic>> get conversations => _conversations;
  Map<String, dynamic>? get currentConversation => _currentConversation;
  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMessages => _isLoadingMessages;

  List<Map<String, String>> _messages = [];
  List<Map<String, String>> get messages => _messages;

  void addUserMessage(String text) {
    _messages.add({'role': 'user', 'content': text});
    notifyListeners();
  }

  void addAgentPlaceholder() {
    _messages.add({'role': 'agent', 'content': 'Finding items for you...'});
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }


  Future<void> sendQuery({
    required String userId,
    required String agencyId,
    required String query,
    String? clientId,
    String? existingConversationId,
  }) async {
    // For backward compatibility, use the old method
    await sendQueryWithMode(
      userId: userId,
      agencyId: agencyId,
      query: query,
      searchMode: 'external_search', // Default to external search for backward compatibility
      clientId: clientId,
      existingConversationId: existingConversationId,
    );
  }

  Future<void> sendQueryWithMode({
    required String userId,
    required String agencyId,
    required String query,
    required String searchMode,
    String? clientId,
    String? existingConversationId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    print("⏳ Sending query to backend with search mode: $searchMode");
    print("User ID: $userId");
    print("Agency ID: $agencyId");
    print("Query: $query");

    // Convert search mode to backend format
    String backendSearchMode;
    switch (searchMode) {
      case 'My knowledge':
        backendSearchMode = 'my_knowledge';
        break;
      case 'External Search':
        backendSearchMode = 'external_search';
        break;
      default:
        backendSearchMode = 'my_knowledge';
    }

    final result = await _searchModeController.sendSearchWithMode(
      userId: userId,
      agencyId: agencyId,
      query: query,
      searchMode: backendSearchMode,
      clientId: clientId,
      conversationId: existingConversationId,
    );

    result.fold(
          (failure) {
        print("❌ Backend error: $failure");
        _error = failure.toString();
        _message = null;
        _externalProducts = [];
        _structuredSummary = null;
      },
          (data) {
        print("✅ Backend success: ${data['success']}");
        
        if (data['success'] == true && data.containsKey('data')) {
          final responseData = data['data'];
          _message = responseData['detailedResponse'] ?? 'Results ready!';
          
          // Store conversation ID if provided
          if (responseData.containsKey('conversationId')) {
            _conversationId = responseData['conversationId'];
          }
          
          // Handle search results based on search mode
          if (responseData.containsKey('searchResults')) {
            final searchResults = responseData['searchResults'];
            _externalProducts = searchResults['externalProducts'] ?? [];
            
            // For My Knowledge search, also include products and experiences
            if (responseData['searchMode'] == 'my_knowledge') {
              final products = searchResults['products'] ?? [];
              final experiences = searchResults['experiences'] ?? [];
              // Combine all results for display
              _externalProducts = [..._externalProducts, ...products, ...experiences];
            }
          } else {
            _externalProducts = [];
          }
          
          // Update messages based on search mode
          _messages.removeWhere((m) => m['role'] == 'agent' && m['content'] == 'Finding items for you...');
          _messages.add({
            'role': 'agent',
            'content': responseData['detailedResponse'] ?? 'Here are the results. Let me know if you want more suggestions or refinements.',
          });
          
          _structuredSummary = responseData['detailedResponse'];
        } else {
          _message = data['message'] ?? 'No results found';
          _externalProducts = [];
          _structuredSummary = null;
        }
        
        print("External products: $_externalProducts");
      },
    );

    _isLoading = false;
    notifyListeners();
  }


  void clearChat() {
    _message = null;
    _externalProducts = [];
    _conversationId = null;
    _error = null;
    _messages.clear();
    notifyListeners();
  }

  // Load conversations for a user
  Future<void> loadConversations(String userId) async {
    _isLoading = true;
    notifyListeners();

    final result = await _searchModeController.getUserConversations(userId: userId);
    
    result.fold(
      (failure) {
        _error = failure.toString();
        _conversations = [];
      },
      (conversations) {
        _conversations = conversations;
        _error = null;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Load a specific conversation
  Future<void> loadConversation(String conversationId) async {
    _isLoading = true;
    notifyListeners();

    final result = await _searchModeController.getConversation(conversationId: conversationId);
    
    result.fold(
      (failure) {
        _error = failure.toString();
        _currentConversation = null;
      },
      (conversation) {
        _currentConversation = conversation;
        _conversationId = conversationId;
        _error = null;
        
        // Load messages from conversation
        if (conversation.containsKey('messages')) {
          _messages = List<Map<String, String>>.from(
            conversation['messages'].map((msg) => {
              'role': msg['role'] ?? 'user',
              'content': msg['content'] ?? '',
            })
          );
        }
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Update conversation name
  Future<void> updateConversationName(String conversationId, String name) async {
    final result = await _searchModeController.updateConversationName(
      conversationId: conversationId,
      name: name,
    );
    
    result.fold(
      (failure) {
        _error = failure.toString();
      },
      (data) {
        // Update the conversation in the list
        final index = _conversations.indexWhere((conv) => conv['_id'] == conversationId);
        if (index != -1) {
          _conversations[index]['name'] = name;
        }
        
        // Update current conversation if it's the same
        if (_currentConversation?['_id'] == conversationId) {
          _currentConversation?['name'] = name;
        }
        
        _error = null;
      },
    );
    
    notifyListeners();
  }

  // Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    final result = await _searchModeController.deleteConversation(conversationId: conversationId);
    
    result.fold(
      (failure) {
        _error = failure.toString();
      },
      (data) {
        // Remove from conversations list
        _conversations.removeWhere((conv) => conv['_id'] == conversationId);
        
        // Clear current conversation if it's the same
        if (_currentConversation?['_id'] == conversationId) {
          _currentConversation = null;
          _conversationId = null;
          _messages.clear();
        }
        
        _error = null;
      },
    );
    
    notifyListeners();
  }

  // Get conversation statistics
  Future<Map<String, dynamic>?> getConversationStats(String userId) async {
    final result = await _searchModeController.getConversationStats(userId: userId);
    
    return result.fold(
      (failure) {
        _error = failure.toString();
        return null;
      },
      (stats) {
        _error = null;
        return stats;
      },
    );
  }

  // Start a new conversation
  void startNewConversation() {
    _conversationId = null;
    _currentConversation = null;
    _messages.clear();
    _message = null;
    _externalProducts = [];
    _structuredSummary = null;
    _error = null;
    notifyListeners();
  }

  // Fetch conversations for an agency
  Future<void> fetchConversations(String agencyId, {int? limit}) async {
    _isLoadingConversations = true;
    _error = null;
    notifyListeners();

    final result = await _conversationController.getConversationsByAgencyId(agencyId);
    
    result.fold(
      (failure) {
        _error = 'Failed to fetch conversations';
        _conversations = [];
        print('Failed to fetch conversations: ${failure.toString()}');
      },
      (conversations) {
        if (limit != null) {
          _conversations = conversations.take(limit).toList();
        } else {
          _conversations = conversations; // Show all conversations
        }
        _error = null;
      },
    );

    _isLoadingConversations = false;
    notifyListeners();
  }

  // Clear conversations
  void clearConversations() {
    _conversations.clear();
    notifyListeners();
  }

  // Load messages for a specific conversation
  Future<void> loadConversationMessages(String conversationId) async {
    _isLoadingMessages = true;
    _error = null;
    notifyListeners();

    try {
      // Find the conversation in the current list
      final conversation = _conversations.firstWhere(
        (conv) => conv['_id'] == conversationId,
        orElse: () => {},
      );

      if (conversation.isNotEmpty && conversation['messages'] != null) {
        // Load messages from the conversation
        _messages = List<Map<String, String>>.from(
          conversation['messages'].map<Map<String, String>>((msg) {
            // Convert dynamic message to Map<String, String>
            final messageMap = Map<String, dynamic>.from(msg);
            return {
              'role': messageMap['role']?.toString() ?? 'user',
              'content': messageMap['content']?.toString() ?? '',
              'searchMode': messageMap['searchMode']?.toString() ?? 'my_knowledge',
            };
          }).toList(),
        );
        _conversationId = conversationId;
        _currentConversation = conversation;
        _error = null;
        print('Successfully loaded ${_messages.length} messages for conversation $conversationId');
      } else {
        _error = 'Conversation not found or has no messages';
        _messages = [];
        print('Failed to find conversation $conversationId or it has no messages. Available conversations: ${_conversations.map((c) => c['_id']).toList()}');
      }
    } catch (e) {
      _error = 'Failed to load conversation messages: $e';
      _messages = [];
      print('Error loading conversation messages: $e');
    }

    _isLoadingMessages = false;
    notifyListeners();
  }

  // Clear current conversation messages
  void clearConversationMessages() {
    _messages.clear();
    _conversationId = null;
    _currentConversation = null;
    notifyListeners();
  }
}
