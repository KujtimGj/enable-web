import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../entities/vicModel.dart';
import '../providers/vicProvider.dart';
import '../providers/userProvider.dart';
import '../utils/vic_mention_utils.dart';

class VICMentionField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;
  final String hintText;
  final Widget? prefixIcon;

  const VICMentionField({
    Key? key,
    required this.controller,
    required this.onSubmitted,
    this.hintText = 'Ask Enable',
    this.prefixIcon,
  }) : super(key: key);

  @override
  State<VICMentionField> createState() => _VICMentionFieldState();
}

class _VICMentionFieldState extends State<VICMentionField> {
  bool _showVicDropdown = false;
  List<VICModel> _filteredVics = [];
  int _selectedVicIndex = 0;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    // Load VICs when the component initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVICs();
    });
  }

  void _loadVICs() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final vicProvider = Provider.of<VICProvider>(context, listen: false);
    
    final agencyId = userProvider.user?.agencyId;
    if (agencyId != null && vicProvider.vics.isEmpty) {
      vicProvider.fetchVICsByAgencyId(agencyId);
    }
  }

  /// Enhances the query with VIC preferences and submits it
  Future<void> _submitQueryWithVICPreferences(String query) async {
    try {
      // Extract VIC mentions and preferences
      final result = await VICMentionUtils.extractVICMentionsAndPreferences(
        query,
        context,
      );
      
      // Use the enhanced query if VIC preferences were found
      final queryToSubmit = result['enhancedQuery'] as String;
      
      // Call the original onSubmitted with the enhanced query
      widget.onSubmitted(queryToSubmit);
    } catch (e) {
      // If there's an error, fall back to the original query
      widget.onSubmitted(query);
    }
  }


  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy - 260,
        width: size.width,
        child: Material(
          color: Color(0xff181616),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: 250,
              minHeight: 50,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[500]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: _filteredVics.isEmpty
                ? Container(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Loading VICs...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                    itemCount: _filteredVics.length,
                    itemBuilder: (context, index) {
                      final vic = _filteredVics[index];
                      final isSelected = index == _selectedVicIndex;

                      return InkWell(
                        onTap: () {
                          print('VICMentionField: VIC card clicked for: ${vic.fullName}');
                          _selectVic(vic);
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Color(0xff181616) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(0xff292525),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (vic.fullName ?? 'V').substring(0, 1).toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
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
                                        vic.fullName ?? 'Unknown VIC',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
    
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final cursorPosition = widget.controller.selection.baseOffset;

    print('VICMentionField: Text changed to: "$text", cursor at: $cursorPosition');

    // Check for @ mentions
    final mentionMatch = _findMentionAtCursor(text, cursorPosition);
    
    if (mentionMatch != null) {
      final query = mentionMatch['query'] as String;
      print('VICMentionField: Found mention with query: "$query"');
      
      setState(() {
        _showVicDropdown = true;
      });
      
      _filterVics(query);
      _showOverlay();
    } else {
      print('VICMentionField: No mention found, hiding dropdown');
      setState(() {
        _showVicDropdown = false;
        _selectedVicIndex = 0;
      });
      _removeOverlay();
    }
  }

  Map<String, dynamic>? _findMentionAtCursor(String text, int cursorPosition) {
    if (text.isEmpty || cursorPosition <= 0) return null;
    
    print('VICMentionField: Looking for mention in text: "$text" at position: $cursorPosition');
    
    // Look backwards from cursor to find @ symbol
    int start = -1;
    for (int i = cursorPosition - 1; i >= 0; i--) {
      if (text[i] == '@') {
        start = i;
        print('VICMentionField: Found @ at position: $start');
        break;
      } else if (text[i] == ' ' || text[i] == '\n' || text[i] == '\t') {
        // Stop if we hit whitespace (not a mention)
        print('VICMentionField: Hit whitespace at position: $i, stopping search');
        break;
      }
    }
    
    if (start == -1) {
      print('VICMentionField: No @ symbol found');
      return null;
    }
    
    // Extract the query after @
    final query = text.substring(start + 1, cursorPosition);
    print('VICMentionField: Extracted query: "$query" from position $start to $cursorPosition');
    
    return {
      'start': start,
      'query': query,
    };
  }

  void _filterVics(String query) {
    final vicProvider = Provider.of<VICProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Get agency ID to fetch VICs
    final agencyId = userProvider.user?.agencyId;
    
    if (agencyId != null && vicProvider.vics.isEmpty) {
      // Load VICs if not already loaded
      vicProvider.fetchVICsByAgencyId(agencyId).then((_) {
        // After VICs are loaded, filter them
        _performVicFiltering(vicProvider, query);
      });
    } else {
      // VICs are already loaded, filter immediately
      _performVicFiltering(vicProvider, query);
    }
  }

  void _performVicFiltering(VICProvider vicProvider, String query) {
    final allVics = vicProvider.vics;
    
    setState(() {
      if (query.isEmpty) {
        // Show all VICs if no query
        _filteredVics = allVics;
      } else {
        // Filter VICs based on query
        _filteredVics = allVics.where((vic) {
          final name = (vic.fullName ?? '').toLowerCase();
          final email = (vic.email ?? '').toLowerCase();
          final queryLower = query.toLowerCase();
          
          return name.contains(queryLower) || email.contains(queryLower);
        }).toList();
      }
      
      _selectedVicIndex = 0;
    });
  }

  void _selectVic(VICModel vic) {
    print('VICMentionField: _selectVic called for: ${vic.fullName}');
    final text = widget.controller.text;
    final currentCursorPosition = widget.controller.selection.baseOffset;
    
    print('VICMentionField: Current text: "$text", cursor at: $currentCursorPosition');
    
    // Try to find mention at different positions if current position doesn't work
    final mentionMatch = _findMentionAtCursor(text, currentCursorPosition);
    
    if (mentionMatch == null) {
      print('VICMentionField: No mention at cursor position, trying end of text');
      // Try at the end of the text
      final endMatch = _findMentionAtCursor(text, text.length);
      if (endMatch != null) {
        print('VICMentionField: Found mention at end of text: $endMatch');
        _replaceMention(text, endMatch, vic);
        return;
      }
      
      print('VICMentionField: No mention found anywhere, cannot replace');
      setState(() {
        _showVicDropdown = false;
        _selectedVicIndex = 0;
      });
      _removeOverlay();
      return;
    }
    
    print('VICMentionField: Found mention match: $mentionMatch');
    _replaceMention(text, mentionMatch, vic);
  }
  
  void _replaceMention(String text, Map<String, dynamic> mentionMatch, VICModel vic) {
    final start = mentionMatch['start'] as int;
    final end = (mentionMatch['start'] as int) + (mentionMatch['query'] as String).length + 1; // +1 for @
    
    // Replace the @mention with @[VIC Name]
    final beforeMention = text.substring(0, start);
    final afterMention = text.substring(end);
    final vicMention = '@${vic.fullName ?? 'Unknown VIC'}';
    
    final newText = beforeMention + vicMention + afterMention;

    print('VICMentionField: Replacing "${text.substring(start, end)}" with "$vicMention"');
    print('VICMentionField: New text: "$newText"');
    
    // Highlight the VIC name by selecting it
    final vicNameStart = start; // Start of @
    final vicNameEnd = start + vicMention.length; // End of VIC name
    
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: vicNameStart,
        extentOffset: vicNameEnd,
      ),
    );
    
    setState(() {
      _showVicDropdown = false;
      _selectedVicIndex = 0;
    });
    _removeOverlay();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (!_showVicDropdown || _filteredVics.isEmpty) return;
    
    if (event.runtimeType.toString().contains('RawKeyDownEvent')) {
      if (event.logicalKey.keyLabel == 'Arrow Down') {
        setState(() {
          _selectedVicIndex = (_selectedVicIndex + 1) % _filteredVics.length;
        });
      } else if (event.logicalKey.keyLabel == 'Arrow Up') {
        setState(() {
          _selectedVicIndex = _selectedVicIndex == 0 
              ? _filteredVics.length - 1 
              : _selectedVicIndex - 1;
        });
      } else if (event.logicalKey.keyLabel == 'Enter') {
        _selectVic(_filteredVics[_selectedVicIndex]);
      } else if (event.logicalKey.keyLabel == 'Escape') {
        setState(() {
          _showVicDropdown = false;
          _selectedVicIndex = 0;
        });
        _removeOverlay();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKeyEvent,
      child: SizedBox(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextFormField(
                onFieldSubmitted: _submitQueryWithVICPreferences,
                controller: widget.controller,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: widget.prefixIcon ?? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SvgPicture.asset(
                      'assets/icons/star-05.svg',
                    ),
                  ),
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
