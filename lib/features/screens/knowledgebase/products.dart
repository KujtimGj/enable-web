import 'package:enable_web/core/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../components/widgets.dart';
import '../../components/responsive_scaffold.dart';
import '../../providers/userProvider.dart';
import '../../providers/productProvider.dart';
import '../../entities/productModel.dart';

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  @override
  void initState() {
    super.initState();
    // Fetch products when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProducts();
    });
  }

  Future<void> _fetchProducts() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    if (userProvider.user?.agencyId != null) {
      await productProvider.fetchProductsByAgencyId(
        userProvider.user!.agencyId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: customForm(context),
        actions: [
          IconButton(
            onPressed: _fetchProducts,
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh products',
          ),
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
                child: Consumer2<UserProvider, ProductProvider>(
                  builder: (context, userProvider, productProvider, child) {
                    if (productProvider.isLoading) {
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

                    if (productProvider.errorMessage != null) {
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
                              productProvider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                productProvider.clearError();
                                _fetchProducts();
                              },
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (productProvider.products.isEmpty) {
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
                        childAspectRatio: 1.7,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                      ),
                      itemCount: productProvider.products.length,
                      itemBuilder: (BuildContext context, int index) {
                        final product = productProvider.products[index];
                        return _buildProductCard(product);
                      },
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

  Widget _buildFeaturesWidget(dynamic features) {
    if (features == null) return SizedBox.shrink();

    if (features is List) {
      // Handle array of features
      if (features.isEmpty) return SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Wrap(
          spacing: 4,
          runSpacing: 2,
          children:
              features
                  .where(
                    (feature) =>
                        feature != null && feature.toString().isNotEmpty,
                  )
                  .map(
                    (feature) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        feature.toString().isNotEmpty
                            ? feature.toString()[0].toUpperCase() +
                                feature.toString().substring(1)
                            : '',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      );
    } else if (features is Map) {
      // Handle object of features
      if (features.isEmpty) return SizedBox.shrink();

      return Wrap(
        spacing: 4,
        runSpacing: 2,
        children:
            features.entries
                .where(
                  (entry) =>
                      entry.value != null && entry.value.toString().isNotEmpty,
                )
                .map(
                  (entry) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[300]!, width: 1),
                    ),
                    child: Text(
                      entry.value.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
      );
    }

    return SizedBox.shrink();
  }

  Widget _buildProductCard(ProductModel product) {
    return _HoverableProductCard(
      onTap: () => _showProductModal(context, product),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF181616),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                      SizedBox(height: 4),
                      // Display features if available
                      if (product.features != null)
                        _buildFeaturesWidget(product.features),
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
      ),
    );
  }

  Widget _buildProductImage(ProductModel product) {
    return Container(
      child: product.images != null && product.images!.isNotEmpty
          ? Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: _buildImageItem(product, 0),
                            ),
                            SizedBox(height: 4),
                            Expanded(
                              child: _buildImageItem(product, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: _buildImageItem(product, 1),
                            ),
                            SizedBox(height: 4),
                            Expanded(
                              child: _buildImageItem(product, 3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : _buildNoImagesPlaceholder(),
    );
  }

  Widget _buildImageItem(ProductModel product, int index) {
    if (index < product.images!.length && 
        product.images![index].signedUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.network(
          product.images![index].signedUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderIcon();
          },
        ),
      );
    } else {
      return _buildPlaceholderIcon();
    }
  }

  Widget _buildNoImagesPlaceholder() {
    return Container(
      height: double.infinity,
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

  Widget _buildPlaceholderIcon() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Color(0xff1e1e1e),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey[600],
          size: 24,
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
                // Header with close button
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
                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side - Images
                        Expanded(
                          flex: ResponsiveUtils.isMobile(context) ? 1 : 2,
                          child: _buildModalImageSection(product),
                        ),
                        SizedBox(width: 16),
                        // Right side - Product details
                        Expanded(
                          flex: 2,
                          child: _buildModalProductDetails(product),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalImageSection(ProductModel product) {
    if (product.images != null && product.images!.isNotEmpty) {
      return Column(
        children: [
          // Main image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: product.images!.isNotEmpty && product.images![0].signedUrl != null
                    ? Image.network(
                        product.images![0].signedUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildModalPlaceholder();
                        },
                      )
                    : _buildModalPlaceholder(),
              ),
            ),
          ),
          SizedBox(height: 8),
          // Thumbnail grid
          if (product.images!.length > 1)
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  for (int i = 1; i < product.images!.length && i < 4; i++)
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: product.images![i].signedUrl != null
                              ? Image.network(
                                  product.images![i].signedUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildModalPlaceholder();
                                  },
                                )
                              : _buildModalPlaceholder(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
    }
    return _buildModalPlaceholder();
  }

  Widget _buildModalPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Color(0xff1e1e1e),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey[600],
          size: 64,
        ),
      ),
    );
  }

  Widget _buildModalProductDetails(ProductModel product) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category
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
          
          // Rating and Price
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
          
          // Description
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
          
          // Features
          if (product.features != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Features',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                _buildFeaturesWidget(product.features),
                SizedBox(height: 16),
              ],
            ),
          
          // Location
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
                SizedBox(height: 16),
              ],
            ),
          
          // Provider Information
          if (product.providerName != null || product.providerWebsite != null || product.providerContact != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Provider Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                if (product.providerName != null)
                  Text(
                    'Name: ${product.providerName!}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[300],
                    ),
                  ),
                if (product.providerWebsite != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Website: ${product.providerWebsite!}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                if (product.providerContact != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Contact: ${product.providerContact!}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                SizedBox(height: 16),
              ],
            ),
          
          // Availability
          if (product.availability != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Availability',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  product.availability!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
        ],
      ),
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
          duration: Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
