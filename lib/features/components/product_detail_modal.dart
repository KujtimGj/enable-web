import 'package:flutter/material.dart';
import 'package:enable_web/features/components/bookmark_components.dart';

class ProductDetailModal extends StatelessWidget {
  final dynamic product;
  final bool isExternalProduct;

  const ProductDetailModal({
    Key? key,
    required this.product,
    required this.isExternalProduct,
  }) : super(key: key);

  // Helper methods to safely access product properties
  String _getProductName() {
    if (product == null) return 'Product Detail';

    try {
      if (isExternalProduct) {
        return product['name']?.toString() ?? 'Product Detail';
      } else {
        if (product is Map) {
          return product['name']?.toString() ?? 'Product Detail';
        } else {
          return product.name?.toString() ?? 'Product Detail';
        }
      }
    } catch (e) {
      return 'Product Detail';
    }
  }

  String _getProductDescription() {
    if (product == null) return 'No description available';

    try {
      if (isExternalProduct) {
        final rawData = product['rawData'];
        if (rawData != null) {
          return rawData['summary']?.toString() ??
              rawData['description']?.toString() ?? 
              product['description']?.toString() ??
              'No description available';
        }
        return product['description']?.toString() ?? 'No description available';
      } else {
        if (product is Map) {
          return product['description']?.toString() ?? 'No description available';
        } else {
          return product.description?.toString() ?? 'No description available';
        }
      }
    } catch (e) {
      return 'No description available';
    }
  }

  Map<String, dynamic> _getProductTags() {
    if (product == null) return {};

    try {
      if (isExternalProduct) {
        return Map<String, dynamic>.from(product['tags'] ?? {});
      } else {
        if (product is Map) {
          return Map<String, dynamic>.from(product['tags'] ?? {});
        } else {
          return Map<String, dynamic>.from(product.tags ?? {});
        }
      }
    } catch (e) {
      return {};
    }
  }

  List<dynamic> _getProductImages() {
    if (product == null) return [];

    try {
      if (isExternalProduct) {
        // For external products, get images from photos array (Google Maps format)
        List<dynamic> images = [];
        
        // Check for photos array first (Google Maps format)
        if (product['photos'] != null && product['photos'].isNotEmpty) {
          for (var photo in product['photos']) {
            if (photo is Map && photo['url'] != null) {
              images.add(photo['url'].toString());
            }
          }
        }
        
        // Check for images array (legacy format)
        if (product['images'] != null && product['images'].isNotEmpty) {
          for (var img in product['images']) {
            if (img is Map && img['imageUrl'] != null) {
              images.add(img['imageUrl'].toString());
            }
          }
        }
        
        // Fallback to rawData imageUrls
        if (images.isEmpty && product['rawData']?['imageUrls'] != null) {
          images = List<dynamic>.from(product['rawData']['imageUrls'] ?? []);
        }
        
        return images;
      } else {
        if (product is Map) {
          return List<dynamic>.from(product['images'] ?? []);
        } else {
          return List<dynamic>.from(product.images ?? []);
        }
      }
    } catch (e) {
      return [];
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // External product specific helper methods
  double? _getRating() {
    if (product == null || !isExternalProduct) return null;
    try {
      return product['rating']?.toDouble();
    } catch (e) {
      return null;
    }
  }

  int? _getTotalReviews() {
    if (product == null || !isExternalProduct) return null;
    try {
      return product['userRatingsTotal']?.toInt();
    } catch (e) {
      return null;
    }
  }

  String? _getAddress() {
    if (product == null || !isExternalProduct) return null;
    try {
      return product['address']?.toString();
    } catch (e) {
      return null;
    }
  }

  bool? _getIsOpen() {
    if (product == null || !isExternalProduct) return null;
    try {
      return product['openingHours']?['openNow'] ?? false;
    } catch (e) {
      return null;
    }
  }

  int? _getPriceLevel() {
    if (product == null || !isExternalProduct) return null;
    try {
      return product['priceLevel']?.toInt();
    } catch (e) {
      return null;
    }
  }

  String _getPriceLevelText(int? priceLevel) {
    if (priceLevel == null) return '';
    switch (priceLevel) {
      case 0: return 'Free';
      case 1: return '\$ (Inexpensive)';
      case 2: return '\$\$ (Moderate)';
      case 3: return '\$\$\$ (Expensive)';
      case 4: return '\$\$\$\$ (Very Expensive)';
      default: return '';
    }
  }

  List<String> _getCategories() {
    if (product == null || !isExternalProduct) return [];
    try {
      List<dynamic> types = product['types'] ?? [];
      return types.map((type) => type.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Color(0xff181616),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Color(0xff292525), width: 1),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                  _buildBookmarkButton(),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getProductName(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          // External product specific information
                          if (isExternalProduct) ...[
                            // Rating and reviews
                            if (_getRating() != null) ...[
                              Row(
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    '${_getRating()!.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_getTotalReviews() != null) ...[
                                    SizedBox(width: 8),
                                    Text(
                                      '(${_getTotalReviews()} reviews)',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 12),
                            ],
                            
                            // Business status and opening hours
                            Row(
                              children: [
                                if (_getIsOpen() != null) ...[
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getIsOpen()! ? Colors.green[700] : Colors.red[700],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getIsOpen()! ? 'Open Now' : 'Closed',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                ],
                                if (_getPriceLevel() != null) ...[
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Color(0xff3A3A3A),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getPriceLevelText(_getPriceLevel()),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 16),
                            
                            // Address
                            if (_getAddress() != null) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.location_on, color: Colors.grey[400], size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _getAddress()!,
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                            ],
                            
                            // Categories
                            if (_getCategories().isNotEmpty) ...[
                              Text(
                                'Categories',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (String category in _getCategories().take(6))
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Color(0xff3A3A3A),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        _capitalizeFirstLetter(category.replaceAll('_', ' ')),
                                        style: TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 20),
                            ],
                          ] else ...[
                            // Database product folder name
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Color(0xff3A3A3A),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.folder, color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Folder name',
                                    style: TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                          
                          // Description
                          Text(
                            _getProductDescription(),
                            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                          ),
                          SizedBox(height: 20),
                          
                          // Tags (for database products)
                          if (!isExternalProduct) ...[
                            Text(
                              'Tags',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (String key in _getProductTags().keys)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Color(0xff292525)),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      _capitalizeFirstLetter(_getProductTags()[key]?.toString() ?? ''),
                                      style: TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: isExternalProduct
                                    ? _buildExternalProductImages()
                                    : _buildDatabaseProductImages(),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExternalProductImages() {
    final images = _getProductImages();
    return _buildImageGrid(images.map((url) => url.toString()).toList());
  }

  Widget _buildDatabaseProductImages() {
    final images = _getProductImages();
    if (images.isNotEmpty) {
      List<String> imageUrls = [];
      for (var img in images) {
        try {
          if (img is Map && img['signedUrl'] != null) {
            imageUrls.add(img['signedUrl'].toString());
          } else if (img.signedUrl != null) {
            imageUrls.add(img.signedUrl.toString());
          }
        } catch (e) {
          continue;
        }
      }
      return _buildImageGrid(imageUrls);
    }
    return _buildImageGrid([]);
  }

  Widget _buildImageGrid(List<String> imageUrls) {
    int imageCount = imageUrls.length;
    int displayCount;
    int placeholderCount = 0;

    if (isExternalProduct) {
      // For external products, show up to 4 images
      if (imageCount >= 4) {
        displayCount = 4;
      } else if (imageCount > 0) {
        displayCount = imageCount;
        placeholderCount = 4 - imageCount;
      } else {
        displayCount = 0;
        placeholderCount = 4;
      }
    } else {
      // For database products, keep original logic
      if (imageCount >= 6) {
        displayCount = 6;
      } else if (imageCount >= 4) {
        displayCount = imageCount;
      } else if (imageCount > 0) {
        displayCount = 1;
        placeholderCount = 3;
      } else {
        displayCount = 0;
        placeholderCount = 4;
      }
    }

    List<Widget> imageWidgets = [];

    for (int i = 0; i < displayCount && i < imageUrls.length; i++) {
      imageWidgets.add(_buildImageItem(imageUrls[i]));
    }

    for (int i = 0; i < placeholderCount; i++) {
      imageWidgets.add(_buildPlaceholderImage());
    }

    if (imageWidgets.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[800],
        child: Icon(Icons.image, color: Colors.white, size: 60),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: imageWidgets.length <= 2 ? 1 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: imageWidgets.length,
      itemBuilder: (context, index) => imageWidgets[index],
    );
  }

  Widget _buildImageItem(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[700],
              child: Icon(Icons.broken_image, color: Colors.white, size: 30),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[600],
        border: Border.all(color: Colors.grey[500]!, width: 1),
      ),
      child: Center(
        child: Icon(Icons.image_outlined, color: Colors.grey[400], size: 30),
      ),
    );
  }

  Widget _buildBookmarkButton() {
    String? productId;
    try {
      if (isExternalProduct) {
        productId = product['_id']?.toString() ?? product['id']?.toString();
      } else {
        if (product is Map) {
          productId = product['_id']?.toString() ?? product['id']?.toString();
        } else {
          productId = product.id?.toString() ?? product._id?.toString();
        }
      }
    } catch (e) {
      print('Error getting product ID: $e');
      return SizedBox.shrink();
    }

    if (productId == null) {
      return SizedBox.shrink();
    }

    return BookmarkButton(
      itemType: isExternalProduct ? 'externalProduct' : 'product',
      itemId: productId,
      color: Colors.white,
      activeColor: Colors.amber,
      size: 24,
    );
  }
}

