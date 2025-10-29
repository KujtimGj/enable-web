import 'package:enable_web/core/responsive_utils.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../components/widgets.dart';
import '../../components/responsive_scaffold.dart';
import '../../components/product_detail_modal.dart';
import '../../providers/userProvider.dart';
import '../../providers/productsProvider.dart';
import '../../providers/externalProductProvider.dart';
import '../../providers/bookmark_provider.dart';
import '../../entities/productModel.dart';
import '../../entities/externalProductModel.dart';
import 'package:flutter_svg/svg.dart';

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  State<Products> createState() => _ProductsState();
}

enum ProductType { products, externalProducts }

class _ProductsState extends State<Products> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  ProductType _selectedProductType = ProductType.products;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
      
      if (userProvider.user?.agencyId != null && productsProvider.products.isEmpty) {
        productsProvider.fetchProducts(userProvider.user!.agencyId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final agencyId = userProvider.user?.agencyId ?? '';

    return ResponsiveScaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) {
            return _HoverableHomeIcon(
              onTap: () => context.go('/home'),
            );
          },
        ),
        centerTitle: true,
        title: Container(
          constraints: BoxConstraints(maxWidth: 500),
          child: TextField(
            controller: _searchController,
            style: TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: TextStyle(fontSize: 14),
              suffixIcon: Icon(Icons.search, size: 20),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue[600]!, width: 1.5),
              ),
            ),
            onChanged: (value) {
              final provider = Provider.of<ProductsProvider>(context, listen: false);
              // Local filtering for responsiveness
              provider.localSearch(value);
              setState(() {});

              // Debounced server-side search for smarter results
              _debounceTimer?.cancel();
              final query = value.trim();
              if (query.isEmpty) {
                provider.clearSearch();
                return;
              }
              _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                provider.serverSearch(query, agencyId, limit: 2000);
              });
            },
          ),
        ),
        actions: [
          customButton(() {
            context.go("/");
          }),
        ],
      ),
      body: ResponsiveContainer(
        child: Row(
          children: [
            bottomLeftBar(),
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.all(10),
                child: Consumer<ProductsProvider>(
                  builder: (context, provider, child) {
                    // Loading state
                    if (provider.isLoading && provider.products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading products...'),
                          ],
                        ),
                      );
                    }

                    // Error state
                    if (provider.errorMessage != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error loading products',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            SelectableText(
                              provider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => provider.refresh(agencyId),
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    // Empty state
                    if (provider.products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Products will appear here once they are added to your agency.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    // Products list (after filters)
                    final filteredProducts = provider.visibleProducts;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product type selector dropdown
                        Container(
                          width:200,
                          height: 36,
                          decoration:BoxDecoration(
                            color: Color(0xff3a3132),
                            borderRadius: BorderRadius.circular(4)
                          ),
                          margin: EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.all(5),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              canvasColor:Color(0xff3a3132),
                              hoverColor:Color(0xff3a3132),
                              focusColor:Color(0xff3a3132),
                              splashColor: Color(0xff3a3132),
                              highlightColor: Color(0xff3a3132),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<ProductType>(
                                isDense: true,
                                isExpanded: true,
                                value: _selectedProductType,
                                items: [
                                  DropdownMenuItem<ProductType>(
                                    value: ProductType.products,
                                    child: Text('Products', style: TextStyle(fontSize: 12, color: Colors.white)),
                                  ),
                                  DropdownMenuItem<ProductType>(
                                    value: ProductType.externalProducts,
                                    child: Text('External Products', style: TextStyle(fontSize: 12, color: Colors.white)),
                                  ),
                                ],
                                onChanged: (ProductType? value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedProductType = value;
                                    });
                                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                                    final agencyId = userProvider.user?.agencyId;
                                    if (agencyId != null) {
                                      if (value == ProductType.externalProducts) {
                                        final externalProductProvider = Provider.of<ExternalProductProvider>(context, listen: false);
                                        externalProductProvider.fetchExternalProductsByAgencyId(agencyId);
                                      } else {
                                        final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
                                        if (productsProvider.products.isEmpty) {
                                          productsProvider.fetchProducts(agencyId);
                                        }
                                      }
                                    }
                                  }
                                },
                                dropdownColor: Color(0xff3a3132),
                                style: TextStyle(color: Colors.white, fontSize: 12),
                                iconSize: 18,
                              ),
                            ),
                          ),
                        ),

                        // Horizontal filter bar
                        _ProductsFilterBar(productType: _selectedProductType),
                        SizedBox(height: 10),

                        // Grid view
                        Expanded(
                          child: _selectedProductType == ProductType.products
                              ? _buildProductsGrid(filteredProducts)
                              : _buildExternalProductsGrid(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid(List<ProductModel> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your search query',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: false,
      physics: AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            ResponsiveUtils.isMobile(context)
                ? 1
                : ResponsiveUtils.isTablet(context)
                ? 2
                : 3,
        childAspectRatio: 1.9,
        mainAxisSpacing: 30,
        crossAxisSpacing: 30,
      ),
      itemCount: products.length,
      itemBuilder: (BuildContext context, int index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildExternalProductsGrid() {
    return Consumer<ExternalProductProvider>(
      builder: (context, externalProvider, child) {
        // Loading state
        if (externalProvider.isLoading && externalProvider.externalProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading external products...'),
              ],
            ),
          );
        }

        // Error state
        if (externalProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                SizedBox(height: 16),
                Text(
                  'Error loading external products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                SelectableText(
                  externalProvider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    final agencyId = userProvider.user?.agencyId;
                    if (agencyId != null) {
                      externalProvider.fetchExternalProductsByAgencyId(agencyId);
                    }
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Empty state
        if (externalProvider.externalProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No external products found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'External products will appear here once they are added to your agency.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final externalProducts = externalProvider.externalProducts;

        return GridView.builder(
          shrinkWrap: false,
          physics: AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                ResponsiveUtils.isMobile(context)
                    ? 1
                    : ResponsiveUtils.isTablet(context)
                    ? 2
                    : 3,
            childAspectRatio: 1.9,
            mainAxisSpacing: 30,
            crossAxisSpacing: 30,
          ),
          itemCount: externalProducts.length,
          itemBuilder: (BuildContext context, int index) {
            final externalProduct = externalProducts[index];
            return _buildExternalProductCard(externalProduct);
          },
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return _HoverableProductCard(
      onTap: () => _showProductModal(context, product),
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 1, child: _buildProductImage(product)),
              SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start, 
                  children: [
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        _buildCardBookmarkButton(product),
                      ],
                    ),
                    SizedBox(height: 4),
                    if (product.category.isNotEmpty)
                      Text(
                        product.category.toString()[0].toUpperCase()+
                            product.category.toString().substring(1),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    SizedBox(height: 4),
                    if (product.description != null &&
                        product.description!.isNotEmpty)
                      Text(
                        product.description!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        if (product.rating != null)
                          Row(
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.amber),
                              SizedBox(width: 4),
                              Text(
                                product.rating!.toString(),
                                style: TextStyle(fontSize: 12),
                              ),
                              SizedBox(width: 16),
                            ],
                          ),
                        if (product.priceMin != null && product.priceMax != null)
                          Text(
                            '\$${product.priceMin!.toStringAsFixed(0)} - \$${product.priceMax!.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExternalProductCard(ExternalProductModel externalProduct) {
    return _HoverableProductCard(
      onTap: () => _showExternalProductModal(context, externalProduct),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 1, child: _buildExternalProductImage(externalProduct)),
              SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start, 
                  children: [
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            externalProduct.name ?? 'Unnamed Product',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        _buildExternalProductBookmarkButton(externalProduct),
                      ],
                    ),
                    SizedBox(height: 4),
                    if (externalProduct.category != null && externalProduct.category!.isNotEmpty)
                      Text(
                        externalProduct.category![0].toUpperCase() +
                            externalProduct.category!.substring(1),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    SizedBox(height: 4),
                    if (externalProduct.description != null &&
                        externalProduct.description!.isNotEmpty)
                      Text(
                        externalProduct.description!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 8),
                    if (externalProduct.city != null || externalProduct.country != null)
                      Text(
                        '${externalProduct.city ?? ''}${externalProduct.city != null && externalProduct.country != null ? ', ' : ''}${externalProduct.country ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(ProductModel product) {
    return Container(
      child: product.images != null && product.images!.isNotEmpty
          ? _buildRandomImageItem(product)
          : _buildNoImagesPlaceholder(),
    );
  }

  Widget _buildRandomImageItem(ProductModel product) {
    if (product.images == null || product.images!.isEmpty) {
      return _buildNoImagesPlaceholder();
    }

    // Use product ID hash to generate a stable "random" index
    final hash = product.id.hashCode;
    final stableIndex = hash.abs() % product.images!.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        product.images![stableIndex].signedUrl!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildNoImagesPlaceholder();
        },
      ),
    );
  }

  Widget _buildNoImagesPlaceholder() {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Color(0xff1e1e1e),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey[600],
          size: 48,
        ),
      ),
    );
  }

  void _showProductModal(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ProductDetailModal(
          product: product,
          isExternalProduct: false,
        );
      },
    );
  }

  void _showExternalProductModal(BuildContext context, ExternalProductModel externalProduct) {
    // Convert ExternalProductModel to Map for the modal
    // Include extras/details at top level so modal can access photos/images directly
    final productMap = externalProduct.toJson();
    if (externalProduct.extras != null) {
      // Add extras fields to top level for easier access by modal
      for (var entry in externalProduct.extras!.entries) {
        if (!productMap.containsKey(entry.key)) {
          productMap[entry.key] = entry.value;
        }
      }
    }
    if (externalProduct.details != null) {
      for (var entry in externalProduct.details!.entries) {
        if (!productMap.containsKey(entry.key)) {
          productMap[entry.key] = entry.value;
        }
      }
    }
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ProductDetailModal(
          product: productMap,
          isExternalProduct: true,
        );
      },
    );
  }

  Widget _buildExternalProductImage(ExternalProductModel externalProduct) {
    // Try to get images from extras which now contains photos/images from backend
    if (externalProduct.extras != null) {
      // Check for photos array first (Google Maps format)
      if (externalProduct.extras!['photos'] != null && externalProduct.extras!['photos'] is List) {
        final photos = externalProduct.extras!['photos'] as List;
        if (photos.isNotEmpty) {
          // Get first photo URL
          for (var photo in photos) {
            if (photo is Map && photo['url'] != null) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  photo['url'].toString(),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildNoImagesPlaceholder();
                  },
                ),
              );
            }
          }
        }
      }
      
      // Check for images array (legacy format)
      if (externalProduct.extras!['images'] != null && externalProduct.extras!['images'] is List) {
        final images = externalProduct.extras!['images'] as List;
        if (images.isNotEmpty) {
          for (var img in images) {
            if (img is Map) {
              final imageUrl = img['imageUrl'] ?? img['signedUrl'];
              if (imageUrl != null) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    imageUrl.toString(),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildNoImagesPlaceholder();
                    },
                  ),
                );
              }
            }
          }
        }
      }
    }
    
    return _buildNoImagesPlaceholder();
  }

  Widget _buildCardBookmarkButton(ProductModel product) {
    final productId = product.id.toString();

    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, child) {
        final isBookmarked = bookmarkProvider.isItemBookmarked('product', productId);
        
        return _BookmarkButton(
          isBookmarked: isBookmarked,
          onTap: () {
            bookmarkProvider.toggleBookmark(
              itemType: 'product',
              itemId: productId,
            );
          },
        );
      },
    );
  }

  Widget _buildExternalProductBookmarkButton(ExternalProductModel externalProduct) {
    final productId = externalProduct.id?.toString() ?? '';

    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, child) {
        final isBookmarked = bookmarkProvider.isItemBookmarked('externalProduct', productId);
        
        return _BookmarkButton(
          isBookmarked: isBookmarked,
          onTap: () {
            bookmarkProvider.toggleBookmark(
              itemType: 'externalProduct',
              itemId: productId,
            );
          },
        );
      },
    );
  }
}

class _HoverableProductCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HoverableProductCard({
    required this.onTap,
    required this.child,
  });

  @override
  State<_HoverableProductCard> createState() => _HoverableProductCardState();
}

class _HoverableProductCardState extends State<_HoverableProductCard> {
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
            borderRadius: BorderRadius.circular(4),
            color: _isHovered ? Color(0xFF211E1E) : Color(0xFF181616),
            border: Border.all(color: _isHovered ? Color(0xFF665B5B) : Color(0xff292525)),
            boxShadow: [], // Explicitly no box shadow
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _ProductsFilterBar extends StatefulWidget {
  final ProductType productType;

  const _ProductsFilterBar({required this.productType});

  @override
  State<_ProductsFilterBar> createState() => _ProductsFilterBarState();
}

class _ProductsFilterBarState extends State<_ProductsFilterBar> {
  String _tagQuery = '';

  @override
  Widget build(BuildContext context) {
    // Only show filters for regular products
    if (widget.productType == ProductType.externalProducts) {
      return SizedBox.shrink();
    }

    return Consumer<ProductsProvider>(
      builder: (context, provider, _) {
        final cats = provider.categories;
        final countries = provider.countries;
        final cities = provider.cities;
        final tags = provider.tagKeys;
        // final filteredTags = _tagQuery.isEmpty
        //     ? tags
        //     : tags.where((t) => t.toLowerCase().contains(_tagQuery.toLowerCase())).toList();

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: _DropdownFilter<String>(
                  label: 'Category',
                  value: provider.selectedCategory,
                  items: cats,
                  onChanged: provider.setCategory,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: _DropdownFilter<String>(
                  label: 'Country',
                  value: provider.selectedCountry,
                  items: countries,
                  onChanged: provider.setCountry,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 36, 
                  child: _DropdownFilter<String>(
                  label: 'City',
                  value: provider.selectedCity,
                  items: cities,
                  onChanged: provider.setCity,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: (tags.isNotEmpty)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 36,
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: TextField(
                              onChanged: (v) {
                                setState(() => _tagQuery = v);
                                provider.setTagTextQuery(v);
                              },
                              style: TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Search tags',
                                hintStyle: TextStyle(fontSize: 12),
                                // Remove visible borders and outlines
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                                suffixIcon: _tagQuery.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () => setState(() => _tagQuery = ''),
                                        icon: Icon(Icons.close, size: 16, color: Colors.grey[400]),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : SizedBox.shrink(),
              ),

              if (provider.hasActiveFilters) ...[
                SizedBox(width: 10),
                SizedBox(
                  height: 36,
                  child: TextButton(
                    onPressed: provider.clearFilters,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[300],
                      padding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text('Clear'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DropdownFilter<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Theme(
        data: Theme.of(context).copyWith(
          // Keep menu dark and overlays non-white so text stays visible
          canvasColor: Colors.black,
          hoverColor: Colors.grey[800],
          focusColor: Colors.grey[800],
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isDense: true,
            isExpanded: true,
            value: value,
            hint: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            items: [
              DropdownMenuItem<T>(
                value: null,
                child: Text('All $label', style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
              ...items.map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(e.toString(), style: TextStyle(fontSize: 12, color: Colors.white)),
              )),
            ],
            onChanged: onChanged,
            dropdownColor: Colors.black,
            style: TextStyle(color: Colors.white, fontSize: 12),
            iconSize: 18,
          ),
        ),
      ),
    );
  }
}

class _BookmarkButton extends StatefulWidget {
  final bool isBookmarked;
  final VoidCallback onTap;

  const _BookmarkButton({
    required this.isBookmarked,
    required this.onTap,
  });

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 40,
          height: 40,
          child: SvgPicture.asset(
            widget.isBookmarked
                ? 'assets/icons/bookmark-selected.svg'
                : _isHovered
                    ? 'assets/icons/bookmark-hover.svg'
                    : 'assets/icons/bookmark-default.svg',
            width: 40,
            height: 40,
          ),
        ),
      ),
    );
  }
}

class _HoverableHomeIcon extends StatefulWidget {
  final VoidCallback onTap;

  const _HoverableHomeIcon({
    required this.onTap,
  });

  @override
  State<_HoverableHomeIcon> createState() => _HoverableHomeIconState();
}

class _HoverableHomeIconState extends State<_HoverableHomeIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              _isHovered ? "assets/icons/home-hover.svg" : "assets/icons/home.svg"
            )
          ],
        ),
      ),
    );
  }
}
