import 'package:enable_web/features/controllers/researchAgent.dart';
import 'package:flutter/foundation.dart';

class ChatProvider extends ChangeNotifier {
  final AIController _chatController = AIController();

  String? _message;
  List<dynamic> _externalProducts = [];
  bool _isLoading = false;
  String? _error;
  String? _conversationId;
  String? _structuredSummary;

  // Getters
  String? get message => _message;
  List<dynamic> get externalProducts => _externalProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get conversationId => _conversationId;
  String? get structuredSummary => _structuredSummary;

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
    _isLoading = true;
    _error = null;
    notifyListeners();

    print("⏳ Sending query to backend...");
    print("User ID: $userId");
    print("Agency ID: $agencyId");
    print("Query: $query");

    final result = await _chatController.sendChatToAgent(
      userId: userId,
      agencyId: agencyId,
      query: query,
      clientId: clientId,
      conversationId: existingConversationId,
    );

    result.fold(
          (failure) {
        print("❌ Backend error: $failure");
        _error = failure.toString();
        _message = null;
        _externalProducts = [];
      },
          (data) {
        print("✅ Backend success: ${data['message']}");
        _message = data['message'] ?? 'Results ready!';
        if (data.containsKey('result') &&
            data['result'] != null &&
            data['result'] is Map<String, dynamic> &&
            data['result'].containsKey('externalProducts')) {
          _externalProducts = data['result']['externalProducts'];
          
          // Extract structured summary if available
          if (data['result'].containsKey('structuredSummary')) {
            _structuredSummary = data['result']['structuredSummary'];
            // Clear messages when summary is available, keep only the summary
            _messages.clear();
          } else {
            // Only show agent message if no summary
            _messages.removeWhere((m) => m['role'] == 'agent' && m['content'] == 'Finding items for you...');
            _messages.add({
              'role': 'agent',
              'content': 'Here are the results. Let me know if you want more suggestions or refinements.',
            });
          }

        } else {
          _externalProducts = [];
          _structuredSummary = null;
        }
        print(_externalProducts);
        _conversationId = data['conversationId'];
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
    notifyListeners();
  }
}
