import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bookmark_provider.dart';

class BookmarkButton extends StatefulWidget {
  final String itemType;
  final String itemId;
  final String? vicId;
  final String? initialNotes;
  final bool showText;
  final double? size;
  final Color? color;
  final Color? activeColor;

  const BookmarkButton({
    Key? key,
    required this.itemType,
    required this.itemId,
    this.vicId,
    this.initialNotes,
    this.showText = false,
    this.size,
    this.color,
    this.activeColor,
  }) : super(key: key);

  @override
  State<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<BookmarkButton> {
  bool _isBookmarked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  void _checkBookmarkStatus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);
      setState(() {
        _isBookmarked = bookmarkProvider.isItemBookmarked(widget.itemType, widget.itemId);
      });
    });
  }

  Future<void> _toggleBookmark() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);
      print('BookmarkButton: BookmarkProvider found, isBookmarked: $_isBookmarked');
      
      if (_isBookmarked) {
        // Delete bookmark
        final bookmark = bookmarkProvider.getBookmarkForItem(widget.itemType, widget.itemId);
        if (bookmark != null) {
          final success = await bookmarkProvider.deleteBookmark(bookmark.id);
          if (success) {
            setState(() {
              _isBookmarked = false;
            });
            _showSnackBar('Bookmark removed', Colors.orange);
          }
        }
      } else {
        // Create bookmark - show dialog for notes
        print('BookmarkButton: Showing bookmark dialog');
        final result = await _showBookmarkDialog();
        print('BookmarkButton: Dialog result: $result');
        if (result != null) {
          print('BookmarkButton: Creating bookmark with data: ${result}');
          final success = await bookmarkProvider.createBookmark(
            itemType: widget.itemType,
            itemId: widget.itemId,
            vicId: result['vicId'],
            notes: result['notes'],
          );
          
          print('BookmarkButton: Create bookmark result: $success');
          if (success) {
            setState(() {
              _isBookmarked = true;
            });
            _showSnackBar('Bookmark added', Colors.green);
          } else {
            print('BookmarkButton: Failed to create bookmark');
            _showSnackBar('Failed to create bookmark', Colors.red);
          }
        } else {
          print('BookmarkButton: Dialog cancelled');
        }
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, String?>?> _showBookmarkDialog() async {
    final TextEditingController notesController = TextEditingController(text: widget.initialNotes ?? '');
    String? selectedVicId = widget.vicId;

    return showDialog<Map<String, String?>>(
      context: context,
      builder: (BuildContext context) {
        return BookmarkDialog(
          notesController: notesController,
          selectedVicId: selectedVicId,
          onVicChanged: (vicId) => selectedVicId = vicId,
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.size ?? 24.0;
    final iconColor = _isBookmarked 
        ? (widget.activeColor ?? Colors.amber) 
        : (widget.color ?? Colors.grey);

    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, child) {
        // Update bookmark status when provider changes
        final isBookmarked = bookmarkProvider.isItemBookmarked(widget.itemType, widget.itemId);
        if (isBookmarked != _isBookmarked) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _isBookmarked = isBookmarked;
            });
          });
        }

        return InkWell(
          onTap: _isLoading ? null : () {
            print('BookmarkButton: InkWell tapped!');
            _toggleBookmark();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(8),
            child: _isLoading
                ? SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        size: iconSize,
                        color: iconColor,
                      ),
                      if (widget.showText) ...[
                        SizedBox(width: 4),
                        Text(
                          _isBookmarked ? 'Bookmarked' : 'Bookmark',
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class BookmarkDialog extends StatefulWidget {
  final TextEditingController notesController;
  final String? selectedVicId;
  final Function(String?) onVicChanged;

  const BookmarkDialog({
    Key? key,
    required this.notesController,
    this.selectedVicId,
    required this.onVicChanged,
  }) : super(key: key);

  @override
  State<BookmarkDialog> createState() => _BookmarkDialogState();
}

class _BookmarkDialogState extends State<BookmarkDialog> {
  String? _selectedVicId;

  @override
  void initState() {
    super.initState();
    _selectedVicId = widget.selectedVicId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF1E1E1E),
      title: Text(
        'Add Bookmark',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes (optional)',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: widget.notesController,
            style: TextStyle(color: Colors.white),
            minLines: 5,
            decoration: InputDecoration(
              hintText: 'Add your notes here...',
              hintStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            maxLines: 100,
          ),
          SizedBox(height: 16),
          Text(
            'Assign to VIC (optional)',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          // VIC selection dropdown - you can implement this based on your VIC data
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Select VIC',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        GestureDetector(
          onTap: (){
            widget.onVicChanged(_selectedVicId);
            Navigator.of(context).pop({
              'notes': widget.notesController.text.trim(),
              'vicId': _selectedVicId,
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(width: 1,color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(10)
            ),
              padding: EdgeInsets.symmetric(horizontal: 20,vertical: 15),
              child: Text('Add Bookmark')
          ),
        ),
      ],
    );
  }
}

class MultiSelectBookmarkButton extends StatelessWidget {
  final String itemType;
  final String itemId;
  final bool isSelected;
  final VoidCallback onTap;

  const MultiSelectBookmarkButton({
    Key? key,
    required this.itemType,
    required this.itemId,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.white70,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              )
            : null,
      ),
    );
  }
}

class MultiSelectToolbar extends StatelessWidget {
  final int selectedCount;
  final bool isMultiSelectMode;
  final VoidCallback onToggleMultiSelect;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onBulkBookmark;
  final VoidCallback onBulkDelete;
  final bool hasBookmarks;

  const MultiSelectToolbar({
    Key? key,
    required this.selectedCount,
    required this.isMultiSelectMode,
    required this.onToggleMultiSelect,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onBulkBookmark,
    required this.onBulkDelete,
    required this.hasBookmarks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isMultiSelectMode) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select items to bookmark',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: onToggleMultiSelect,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Select Multiple',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: Colors.blue.withOpacity(0.3)),
          bottom: BorderSide(color: Colors.blue.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          // Selection count
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$selectedCount selected',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 12),
          
          // Action buttons
          Expanded(
            child: Row(
              children: [
                GestureDetector(
                  onTap: onSelectAll,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Select All',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: onClearSelection,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main action buttons
          Row(
            children: [
              if (hasBookmarks)
                GestureDetector(
                  onTap: onBulkDelete,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Remove Bookmarks',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: onBulkBookmark,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Bookmark Selected',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: onToggleMultiSelect,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BulkBookmarkDialog extends StatefulWidget {
  final List<Map<String, String>> selectedItems;
  final Function(String?, String?) onConfirm;

  const BulkBookmarkDialog({
    Key? key,
    required this.selectedItems,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<BulkBookmarkDialog> createState() => _BulkBookmarkDialogState();
}

class _BulkBookmarkDialogState extends State<BulkBookmarkDialog> {
  final TextEditingController _notesController = TextEditingController();
  String? _selectedVicId;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF1E1E1E),
      title: Row(
        children: [
          Icon(Icons.bookmark_add, color: Colors.blue, size: 24),
          SizedBox(width: 8),
          Text(
            'Bookmark ${widget.selectedItems.length} Items',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected items preview
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Items:',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...widget.selectedItems.take(5).map((item) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          _getItemTypeIcon(item['itemType']!),
                          color: Colors.white70,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_getItemTypeDisplayName(item['itemType']!)} - ${item['itemId']!.substring(0, 8)}...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (widget.selectedItems.length > 5)
                    Text(
                      '... and ${widget.selectedItems.length - 5} more',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // Notes section
            Text(
              'Notes (optional)',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _notesController,
              style: TextStyle(color: Colors.white),
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Add notes for all bookmarks...',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // VIC assignment section
            Text(
              'Assign to VIC (optional)',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'VIC selection not implemented yet',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        GestureDetector(
          onTap: () {
            widget.onConfirm(_selectedVicId, _notesController.text.trim());
            Navigator.of(context).pop();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Text(
              'Bookmark All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getItemTypeIcon(String itemType) {
    switch (itemType) {
      case 'product':
        return Icons.inventory;
      case 'externalProduct':
        return Icons.shopping_bag;
      case 'experience':
        return Icons.explore;
      case 'file':
        return Icons.description;
      case 'conversation':
        return Icons.chat;
      default:
        return Icons.bookmark;
    }
  }

  String _getItemTypeDisplayName(String itemType) {
    switch (itemType) {
      case 'product':
        return 'Product';
      case 'externalProduct':
        return 'External Product';
      case 'experience':
        return 'Experience';
      case 'file':
        return 'File';
      case 'conversation':
        return 'Conversation';
      default:
        return 'Item';
    }
  }
}

class BookmarkListTile extends StatelessWidget {
  final String itemType;
  final String itemId;
  final String? notes;
  final String? vicName;
  final DateTime createdAt;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const BookmarkListTile({
    Key? key,
    required this.itemType,
    required this.itemId,
    this.notes,
    this.vicName,
    required this.createdAt,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  String _getItemTypeDisplayName() {
    switch (itemType) {
      case 'product':
        return 'Product';
      case 'externalProduct':
        return 'External Product';
      case 'experience':
        return 'Experience';
      case 'file':
        return 'File';
      case 'conversation':
        return 'Conversation';
      default:
        return 'Item';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFF2A2A2A),
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Icon(
          _getItemTypeIcon(),
          color: Colors.blue,
        ),
        title: Text(
          _getItemTypeDisplayName(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notes != null && notes!.isNotEmpty)
              Text(
                notes!,
                style: TextStyle(color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (vicName != null)
              Text(
                'VIC: $vicName',
                style: TextStyle(color: Colors.blue, fontSize: 12),
              ),
            Text(
              'Added ${_formatDate(createdAt)}',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  IconData _getItemTypeIcon() {
    switch (itemType) {
      case 'product':
        return Icons.inventory;
      case 'externalProduct':
        return Icons.shopping_bag;
      case 'experience':
        return Icons.explore;
      case 'file':
        return Icons.description;
      case 'conversation':
        return Icons.chat;
      default:
        return Icons.bookmark;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
