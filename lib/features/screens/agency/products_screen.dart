import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:enable_web/features/components/responsive_scaffold.dart';
import 'package:enable_web/features/providers/agencyProvider.dart';
import 'package:enable_web/features/providers/userProvider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Products',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/knowledgebase'),
        ),
      ),
      body: ResponsiveContainer(
        child: Consumer2<UserProvider, AgencyProvider>(
          builder: (context, userProvider, agencyProvider, child) {
            // Determine which agency ID to use
            String? agencyId;
            if (agencyProvider.isAuthenticated && agencyProvider.agency != null) {
              agencyId = agencyProvider.agency!.id;
            } else if (userProvider.isAuthenticated && userProvider.user != null) {
              final user = userProvider.user;
              if (user?.agencyId != null && user!.agencyId.isNotEmpty) {
                agencyId = user.agencyId;
              }
            }

            // Fetch data if we have an agency ID and data is not already loaded
            if (agencyId != null && agencyProvider.products.isEmpty && !agencyProvider.isLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                agencyProvider.fetchAgencyProducts(agencyId!);
              });
            }

            if (agencyProvider.isLoading) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            if (agencyProvider.errorMessage != null) {
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
                    Text(
                      agencyProvider.errorMessage!,
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (agencyId != null) {
                          agencyProvider.fetchAgencyProducts(agencyId);
                        }
                      },
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final products = agencyProvider.products;

            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
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
                      'Products will appear here when they are added.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(
                        Icons.inventory,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      product.name ?? 'Unnamed Product',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.description != null)
                          Text(
                            product.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.category, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              product.category ?? 'No category',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to detailed view
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Product: ${product.name ?? 'Unnamed Product'}'),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
