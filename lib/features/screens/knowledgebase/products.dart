import 'package:enable_web/core/responsive_utils.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../components/widgets.dart';
import '../../components/responsive_scaffold.dart';
import '../../providers/userProvider.dart';
import '../../providers/productsProvider.dart';
import '../../entities/productModel.dart';

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

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
              Text("Products", style: TextStyle(fontSize: 14)),
            ],
          ),
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
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      children: [

                        // Horizontal filter bar
                        _ProductsFilterBar(),
                        SizedBox(height: 10),

                        // Grid view
                        Expanded(
                          child: filteredProducts.isEmpty
                              ? Center(
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
                                )
                              : GridView.builder(
                                  shrinkWrap: false,
                                  physics: AlwaysScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        ResponsiveUtils.isMobile(context)
                                            ? 1
                                            : ResponsiveUtils.isTablet(context)
                                            ? 2
                                            : 3,
                                    childAspectRatio: 1.7,
                                    mainAxisSpacing: 20,
                                    crossAxisSpacing: 20,
                                  ),
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final product = filteredProducts[index];
                                    return _buildProductCard(product);
                                  },
                                ),
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

  Widget _buildProductCard(ProductModel product) {
    return _HoverableProductCard(
      onTap: () => _showProductModal(context, product),
        child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 1, child: _buildProductImage(product)),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Text(
                      product.name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
      borderRadius: BorderRadius.circular(5),
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
        borderRadius: BorderRadius.circular(5),
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
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: ResponsiveUtils.isMobile(context) ? 
                MediaQuery.of(context).size.width * 0.95 : 
                MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey, width: 1),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.category.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue[600]!, width: 1),
                            ),
                            child: Text(
                              product.category.toString()[0].toUpperCase() +
                                  product.category.toString().substring(1),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            if (product.rating != null)
                              Row(
                                children: [
                                  Icon(Icons.star, size: 20, color: Colors.amber),
                                  SizedBox(width: 4),
                                  Text(
                                    product.rating!.toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                ],
                              ),
                            if (product.priceMin != null && product.priceMax != null)
                              Text(
                                '\$${product.priceMin!.toStringAsFixed(0)} - \$${product.priceMax!.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 16),
                        if (product.description != null && product.description!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                product.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[300],
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                        if (product.country != null || product.city != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${product.city ?? ''} ${product.country ?? ''}'.trim(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[300],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            borderRadius: BorderRadius.circular(10),
            color: _isHovered ? Color(0xFF211E1E) : Color(0xFF181616),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _ProductsFilterBar extends StatefulWidget {
  @override
  State<_ProductsFilterBar> createState() => _ProductsFilterBarState();
}

class _ProductsFilterBarState extends State<_ProductsFilterBar> {
  String _tagQuery = '';

  @override
  Widget build(BuildContext context) {
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
