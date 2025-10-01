import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClarifyingQuestionsWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final Function(String) onFollowUpSubmitted;

  const ClarifyingQuestionsWidget({
    super.key,
    required this.message,
    required this.onFollowUpSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    // Return empty container - no suggestion buttons
    return Container();
  }
}

class EnhancedMessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final Function(String) onFollowUpSubmitted;

  const EnhancedMessageBubble({
    super.key,
    required this.message,
    required this.onFollowUpSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message['role'] == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Main message bubble - keeping original design
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Color(0xff292525) : Colors.transparent,
                border: isUser ? null : Border.all(
                  color: Color(0xff292525),
                  width: 1,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomLeft: isUser ? Radius.circular(10) : Radius.circular(0),
                  bottomRight: isUser ? Radius.circular(0) : Radius.circular(10),
                ),
              ),
              child: SelectableText.rich(
                TextSpan(
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  children: _parseMarkdownText(message['content'] ?? ''),
                ),
                onSelectionChanged: (selection, cause) {
                  // Handle text selection if needed
                },
              ),
            ),

            // No suggestion buttons - agent responses are selectable text only
          ],
        ),
      ),
    );
  }

  /// Cleans and normalizes the raw text from agent responses
  String _cleanAgentResponse(String text) {
    // Fix common formatting issues with bold markers
    text = text.replaceAll(RegExp(r'\*\*\s+'), '**'); // Remove space after **
    text = text.replaceAll(RegExp(r'\s+\*\*'), '**'); // Remove space before **
    
    // Ensure proper spacing around section headers with callback function
    text = text.replaceAllMapped(RegExp(r'\*\*([^*]+):\*\*'), (match) {
      return '\n\n**${match.group(1)}:**\n';
    });
    
    // Ensure bullet points start on new lines
    text = text.replaceAllMapped(RegExp(r'([^\n])\s*•\s*'), (match) {
      return '${match.group(1)}\n• ';
    });
    
    text = text.replaceAllMapped(RegExp(r'([^\n])\s*-\s+'), (match) {
      return '${match.group(1)}\n- ';
    });
    
    // Clean up multiple newlines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    // Remove excessive spaces (but keep newlines)
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    
    return text.trim();
  }

  List<TextSpan> _parseMarkdownText(String text) {
    // Clean the text first
    text = _cleanAgentResponse(text);
    
    List<TextSpan> spans = [];
    List<String> lines = text.split('\n');
    
    for (String line in lines) {
      if (line.trim().isEmpty) {
        spans.add(TextSpan(text: '\n'));
        continue;
      }
      
      // Handle lines with inline formatting (bold, italic, code, etc.)
      if (_hasInlineFormatting(line)) {
        spans.addAll(_parseInlineFormatting(line));
        spans.add(TextSpan(text: '\n'));
        continue;
      }
      
      // Handle markdown headers (# text)
      if (line.trim().startsWith('# ')) {
        spans.add(TextSpan(
          text: line.trim().substring(2) + '\n',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ));
      }
      // Handle subheaders (## text)
      else if (line.trim().startsWith('## ')) {
        spans.add(TextSpan(
          text: line.trim().substring(3) + '\n',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.grey[100],
          ),
        ));
      }
      // Handle section headers (text ending with :)
      else if (line.trim().endsWith(':') && line.trim().split(' ').length <= 3) {
        spans.add(TextSpan(
          text: line.trim() + '\n',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.white,
          ),
        ));
      }
      // Handle bullet points with • character
      else if (line.trim().startsWith('• ')) {
        spans.add(TextSpan(
          text: '  ${line.trim()}\n',
          style: TextStyle(
            color: Colors.grey[200],
            height: 1.5,
          ),
        ));
      }
      // Handle markdown bullet points (- text)
      else if (line.trim().startsWith('- ')) {
        spans.add(TextSpan(
          text: '  • ${line.trim().substring(2)}\n',
          style: TextStyle(
            color: Colors.grey[200],
            height: 1.5,
          ),
        ));
      }
      // Handle numbered lists (1. text)
      else if (RegExp(r'^\d+\.\s').hasMatch(line.trim())) {
        spans.add(TextSpan(
          text: '  ${line.trim()}\n',
          style: TextStyle(
            color: Colors.grey[200],
            height: 1.5,
          ),
        ));
      }
      // Regular text
      else {
        spans.add(TextSpan(
          text: line + '\n',
          style: TextStyle(
            height: 1.4,
            color: Colors.white,
          ),
        ));
      }
    }
    
    return spans;
  }

  /// Checks if a line contains inline formatting markers
  bool _hasInlineFormatting(String line) {
    return line.contains('**') || 
           line.contains('`') ||
           (line.contains('[') && line.contains('](') && line.contains(')')) ||
           (line.contains('*') && !line.startsWith('*') && !line.endsWith('*'));
  }

  /// Parses a line with inline formatting (bold, italic, code, links)
  List<TextSpan> _parseInlineFormatting(String line) {
    List<TextSpan> spans = [];
    String remaining = line;
    
    while (remaining.isNotEmpty) {
      // Find the earliest formatting marker
      int boldIndex = remaining.indexOf('**');
      int codeIndex = remaining.indexOf('`');
      int linkIndex = remaining.indexOf('[');
      
      // Find the minimum valid index
      int nextIndex = -1;
      String? formatType;
      
      if (boldIndex != -1 && (nextIndex == -1 || boldIndex < nextIndex)) {
        nextIndex = boldIndex;
        formatType = 'bold';
      }
      if (codeIndex != -1 && (nextIndex == -1 || codeIndex < nextIndex)) {
        nextIndex = codeIndex;
        formatType = 'code';
      }
      if (linkIndex != -1 && (nextIndex == -1 || linkIndex < nextIndex)) {
        nextIndex = linkIndex;
        formatType = 'link';
      }
      
      // If no formatting found, add remaining text
      if (nextIndex == -1) {
        spans.add(TextSpan(
          text: remaining,
          style: TextStyle(color: Colors.white, height: 1.4),
        ));
        break;
      }
      
      // Add text before formatting
      if (nextIndex > 0) {
        spans.add(TextSpan(
          text: remaining.substring(0, nextIndex),
          style: TextStyle(color: Colors.white, height: 1.4),
        ));
      }
      
      // Process formatting
      if (formatType == 'bold') {
        int endIndex = remaining.indexOf('**', nextIndex + 2);
        if (endIndex != -1) {
          String boldText = remaining.substring(nextIndex + 2, endIndex);
          spans.add(TextSpan(
            text: boldText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
              height: 1.4,
            ),
          ));
          remaining = remaining.substring(endIndex + 2);
        } else {
          // No closing **, treat as regular text
          spans.add(TextSpan(
            text: remaining.substring(nextIndex),
            style: TextStyle(color: Colors.white, height: 1.4),
          ));
          break;
        }
      } else if (formatType == 'code') {
        int endIndex = remaining.indexOf('`', nextIndex + 1);
        if (endIndex != -1) {
          String codeText = remaining.substring(nextIndex + 1, endIndex);
          spans.add(TextSpan(
            text: codeText,
            style: TextStyle(
              fontFamily: 'monospace',
              backgroundColor: Colors.grey[800],
              color: Colors.green[300],
              height: 1.4,
            ),
          ));
          remaining = remaining.substring(endIndex + 1);
        } else {
          spans.add(TextSpan(
            text: remaining.substring(nextIndex),
            style: TextStyle(color: Colors.white, height: 1.4),
          ));
          break;
        }
      } else if (formatType == 'link') {
        RegExp linkRegex = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
        Match? match = linkRegex.firstMatch(remaining.substring(nextIndex));
        if (match != null) {
          String linkText = match.group(1) ?? '';
          spans.add(TextSpan(
            text: linkText,
            style: TextStyle(
              decoration: TextDecoration.underline,
              color: Colors.blue[300],
              height: 1.4,
            ),
          ));
          remaining = remaining.substring(nextIndex + match.group(0)!.length);
        } else {
          spans.add(TextSpan(
            text: remaining.substring(nextIndex),
            style: TextStyle(color: Colors.white, height: 1.4),
          ));
          break;
        }
      }
    }
    
    return spans;
  }
}
