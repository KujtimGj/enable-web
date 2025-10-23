import 'package:enable_web/features/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/widgets.dart';
import '../../providers/bookmark_provider.dart';

class Bookmarks extends StatefulWidget {
  const Bookmarks({super.key});

  @override
  State<Bookmarks> createState() => _BookmarksState();
}

class _BookmarksState extends State<Bookmarks> {
  String _selectedItemType = 'all';
  String _selectedVic = 'all';
  List<dynamic> _filteredBookmarks = [];

  final List<String> _itemTypes = [
    'all',
    'product',
    'externalProduct',
    'experience',
    'conversation',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookmarks();
    });
  }

  void _loadBookmarks() {
    final bookmarkProvider = Provider.of<BookmarkProvider>(
      context,
      listen: false,
    );
    // Load bookmarks - the provider will handle the API call
    bookmarkProvider.fetchUserBookmarks();
  }

  void _applyFilters() {
    final bookmarkProvider = Provider.of<BookmarkProvider>(
      context,
      listen: false,
    );
    List<dynamic> bookmarks = List.from(bookmarkProvider.bookmarks);

    // Apply item type filter
    if (_selectedItemType != 'all') {
      bookmarks =
          bookmarks
              .where(
                (bookmark) =>
                    _getBookmarkProperty(bookmark, 'itemType') ==
                    _selectedItemType,
              )
              .toList();
    }

    // Apply VIC filter
    if (_selectedVic != 'all') {
      bookmarks =
          bookmarks
              .where(
                (bookmark) =>
                    _getBookmarkProperty(bookmark, 'vicId') == _selectedVic,
              )
              .toList();
    }

    setState(() {
      _filteredBookmarks = bookmarks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 65,
        automaticallyImplyLeading: false,
        leadingWidth: 120,
        leading: GestureDetector(
          onTap: () => context.go('/home'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, size: 20),
              SizedBox(width: 4),
              Text("Bookmarks", style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        centerTitle: true,
        title: customForm(context),
        actions: [
          customButton(() {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
            );
          }),
        ],
      ),
      body: Consumer<BookmarkProvider>(
        builder: (context, bookmarkProvider, child) {
          if (bookmarkProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (bookmarkProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error loading bookmarks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  SelectableText(bookmarkProvider.error!),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBookmarks,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Update filtered bookmarks when provider data changes
          WidgetsBinding.instance.addPostFrameCallback((_) { 
            _applyFilters();
          });

          return Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                                  _getItemTypeDisplayName(_selectedItemType),
                                  style: TextStyle(color: Colors.white),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          );
                        },
                        menuChildren:
                        _itemTypes.map<Widget>((String value) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedItemType = value;
                                _applyFilters();
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              child: Text(
                                _getItemTypeDisplayName(value),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  ],
                ),
              ),

              // Bookmarks List
              Expanded(
                child:
                    _filteredBookmarks.isEmpty
                        ? _buildEmptyState()
                        : _buildBookmarksGrid(bookmarkProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookmarksGrid(BookmarkProvider bookmarkProvider) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16,vertical: 10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.9,
        mainAxisSpacing: 30,
        crossAxisSpacing: 30,
      ),
      itemCount: _filteredBookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = _filteredBookmarks[index];
        return _buildBookmarkGridCard(bookmark, bookmarkProvider);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 64, color: Colors.grey[600]),
          SizedBox(height: 16),
          Text(
            'No bookmarks found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your filters or create some bookmarks',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkGridCard(
    dynamic bookmark,
    BookmarkProvider bookmarkProvider,
  ) {
    // Handle both Map and Model objects
    final item = _getBookmarkItem(bookmark);
    if (item == null) {
      return _buildBookmarkCard(bookmark, bookmarkProvider);
    }

    // Extract images from the item
    List<dynamic> images = _getItemImages(item);

    return _HoverableBookmarkCard(
      onTap: () => _showBookmarkDetails(bookmark),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: 2.5, bottom: 2.5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(4)),
                              color: Color(0xff292525),
                              image: images.isNotEmpty && images[0] != null && (images[0]['signedUrl'] ?? images[0]['imageUrl']) != null
                                  ? DecorationImage(
                                      image: NetworkImage(images[0]['signedUrl'] ?? images[0]['imageUrl']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: (images.isEmpty || images[0] == null || (images[0]['signedUrl'] ?? images[0]['imageUrl']) == null)
                                ? Icon(Icons.image_outlined, color: Colors.grey[600], size: 24)
                                : null,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(left: 2.5, bottom: 2.5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(topRight: Radius.circular(4)),
                              color: Color(0xff292525),
                              image: images.length > 1 && images[1] != null && (images[1]['signedUrl'] ?? images[1]['imageUrl']) != null
                                  ? DecorationImage(
                                      image: NetworkImage(images[1]['signedUrl'] ?? images[1]['imageUrl']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: (images.length <= 1 || images[1] == null || (images[1]['signedUrl'] ?? images[1]['imageUrl']) == null)
                                ? Icon(Icons.image_outlined, color: Colors.grey[600], size: 24)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: 2.5, top: 2.5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4)),
                              color: Color(0xff292525),
                              image: images.length > 2 && images[2] != null && (images[2]['signedUrl'] ?? images[2]['imageUrl']) != null
                                  ? DecorationImage(
                                      image: NetworkImage(images[2]['signedUrl'] ?? images[2]['imageUrl']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: (images.length <= 2 || images[2] == null || (images[2]['signedUrl'] ?? images[2]['imageUrl']) == null)
                                ? Icon(Icons.image_outlined, color: Colors.grey[600], size: 24)
                                : null,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(left: 2.5, top: 2.5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(bottomRight: Radius.circular(4)),
                              color: Color(0xff292525),
                              image: images.length > 3 && images[3] != null && (images[3]['signedUrl'] ?? images[3]['imageUrl']) != null
                                  ? DecorationImage(
                                      image: NetworkImage(images[3]['signedUrl'] ?? images[3]['imageUrl']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: (images.length <= 3 || images[3] == null || (images[3]['signedUrl'] ?? images[3]['imageUrl']) == null)
                                ? Icon(Icons.image_outlined, color: Colors.grey[600], size: 24)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                            _getItemProperty(item, 'name').isNotEmpty
                                ? _getItemProperty(item, 'name')
                                : 'Unknown Item',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Bookmark indicator
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Color(0xFF292525),
                            border: Border.all(
                              color: Color(0xFF292525),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    if (_getItemProperty(item, 'category').isNotEmpty)
                      Text(
                        _capitalizeFirst(_getItemProperty(item, 'category')),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    if (_getItemProperty(item, 'country').isNotEmpty &&
                        _getItemProperty(item, 'city').isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        '${_capitalizeFirst(_getItemProperty(item, 'city'))}, ${_capitalizeFirst(_getItemProperty(item, 'country'))}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                    Spacer(),
                    // Notes section
                    if (_getBookmarkProperty(bookmark, 'notes').isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getBookmarkProperty(bookmark, 'notes'),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
  }


  Widget _buildBookmarkCard(
    dynamic bookmark,
    BookmarkProvider bookmarkProvider,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: InkWell(
        onTap: () => _showBookmarkDetails(bookmark),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getItemTypeDisplayName(
                            _getBookmarkProperty(bookmark, 'itemType'),
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${_getBookmarkProperty(bookmark, 'itemId').substring(0, 8)}...',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Notes
              if (_getBookmarkProperty(bookmark, 'notes').isNotEmpty) ...[
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getBookmarkProperty(bookmark, 'notes'),
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],

              // Footer
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created ${_formatDate(DateTime.tryParse(_getBookmarkProperty(bookmark, 'createdAt')) ?? DateTime.now())}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  if (_getBookmarkProperty(bookmark, 'vicId').isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'VIC Assigned',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookmarkDetails(dynamic bookmark) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Color(0xFF1E1E1E),
            title: Row(
              children: [
                Icon(
                  _getItemTypeIcon(bookmark.itemType),
                  color: _getItemTypeColor(bookmark.itemType),
                ),
                SizedBox(width: 8),
                Text('Bookmark Details', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow(
                    'Item Type',
                    _getItemTypeDisplayName(
                      _getBookmarkProperty(bookmark, 'itemType'),
                    ),
                  ),
                  _buildDetailRow(
                    'Item ID',
                    _getBookmarkProperty(bookmark, 'itemId'),
                  ),
                  if (_getBookmarkProperty(bookmark, 'notes').isNotEmpty)
                    _buildDetailRow(
                      'Notes',
                      _getBookmarkProperty(bookmark, 'notes'),
                    ),
                  if (_getBookmarkProperty(bookmark, 'vicId').isNotEmpty)
                    _buildDetailRow(
                      'VIC ID',
                      _getBookmarkProperty(bookmark, 'vicId'),
                    ),
                  _buildDetailRow(
                    'Created',
                    _formatDate(
                      DateTime.tryParse(
                            _getBookmarkProperty(bookmark, 'createdAt'),
                          ) ??
                          DateTime.now(),
                    ),
                  ),
                  _buildDetailRow(
                    'Updated',
                    _formatDate(
                      DateTime.tryParse(
                            _getBookmarkProperty(bookmark, 'updatedAt'),
                          ) ??
                          DateTime.now(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value, style: TextStyle(color: Colors.white))),
        ],
      ),
    );
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
      case 'custom':
        return 'Custom';
      default:
        return 'All';
    }
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
      case 'custom':
        return Icons.bookmark;
      default:
        return Icons.help_outline;
    }
  }

  Color _getItemTypeColor(String itemType) {
    switch (itemType) {
      case 'product':
        return Colors.green;
      case 'externalProduct':
        return Colors.blue;
      case 'experience':
        return Colors.purple;
      case 'file':
        return Colors.orange;
      case 'conversation':
        return Colors.teal;
      case 'custom':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String _capitalizeFirst(String input) {
    if (input.isEmpty) return input;
    final String firstCharacterUpper = input[0].toUpperCase();
    if (input.length == 1) return firstCharacterUpper;
    return firstCharacterUpper + input.substring(1);
  }

  // Helper methods to safely access bookmark properties
  dynamic _getBookmarkItem(dynamic bookmark) {
    if (bookmark is Map) {
      return bookmark['item'];
    } else if (bookmark is BookmarkModel) {
      return bookmark.item;
    } else {
      // Handle other object types
      try {
        return bookmark.item;
      } catch (e) {
        return null;
      }
    }
  }

  String _getBookmarkProperty(dynamic bookmark, String property) {
    if (bookmark is Map) {
      return bookmark[property]?.toString() ?? '';
    } else if (bookmark is BookmarkModel) {
      switch (property) {
        case 'itemType':
          return bookmark.itemType;
        case 'itemId':
          return bookmark.itemId;
        case 'notes':
          return bookmark.notes;
        case 'vicId':
          return bookmark.vicId ?? '';
        case 'createdAt':
          return bookmark.createdAt.toIso8601String();
        case 'updatedAt':
          return bookmark.updatedAt.toIso8601String();
        case '_id':
        case 'id':
          return bookmark.id;
        default:
          return '';
      }
    } else {
      // Handle other object types
      try {
        switch (property) {
          case 'itemType':
            return bookmark.itemType?.toString() ?? '';
          case 'itemId':
            return bookmark.itemId?.toString() ?? '';
          case 'notes':
            return bookmark.notes?.toString() ?? '';
          case 'vicId':
            return bookmark.vicId?.toString() ?? '';
          case 'createdAt':
            return bookmark.createdAt?.toString() ?? '';
          case 'updatedAt':
            return bookmark.updatedAt?.toString() ?? '';
          case '_id':
          case 'id':
            return bookmark.id?.toString() ?? '';
          default:
            return '';
        }
      } catch (e) {
        return '';
      }
    }
  }

  String _getItemProperty(dynamic item, String property) {
    if (item is Map) {
      return item[property]?.toString() ?? '';
    } else {
      // Handle item model object
      try {
        switch (property) {
          case 'name':
            return item.name?.toString() ?? '';
          case 'category':
            return item.category?.toString() ?? '';
          case 'city':
            return item.city?.toString() ?? '';
          case 'country':
            return item.country?.toString() ?? '';
          default:
            return '';
        }
      } catch (e) {
        return '';
      }
    }
  }

  List<dynamic> _getItemImages(dynamic item) {
    if (item is Map) {
      return item['images'] ?? [];
    } else {
      // Handle item model object
      try {
        return item.images ?? [];
      } catch (e) {
        return [];
      }
    }
  }
}

class _HoverableBookmarkCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HoverableBookmarkCard({
    required this.onTap,
    required this.child,
  });

  @override
  State<_HoverableBookmarkCard> createState() => _HoverableBookmarkCardState();
}

class _HoverableBookmarkCardState extends State<_HoverableBookmarkCard> {
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
            borderRadius: BorderRadius.circular(10),
            color: _isHovered ? Color(0xFF211E1E) : Color(0xFF181616),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
