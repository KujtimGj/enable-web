import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:enable_web/features/components/responsive_scaffold.dart';
import 'package:enable_web/features/providers/agencyProvider.dart';
import 'package:enable_web/features/providers/userProvider.dart';

class ExternalProductsScreen extends StatefulWidget {
  const ExternalProductsScreen({super.key});

  @override
  State<ExternalProductsScreen> createState() => _ExternalProductsScreenState();
}

class _ExternalProductsScreenState extends State<ExternalProductsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'External Products',
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
            if (userProvider.isAuthenticated && userProvider.user != null) {
              final user = userProvider.user;
              if (user?.agencyId != null && user!.agencyId.isNotEmpty) {
                agencyId = user.agencyId;
              }
            }

            // Fetch data if we have an agency ID and data is not already loaded
            if (agencyId != null && agencyProvider.externalProducts.isEmpty && !agencyProvider.isLoadingData) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                agencyProvider.fetchExternalProducts(agencyId!);
              });
            }

            if (agencyProvider.isLoadingData) {
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
                      'Error loading external products',
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
                          agencyProvider.fetchExternalProducts(agencyId!);
                        }
                      },
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final externalProducts = agencyProvider.externalProducts;

            if (externalProducts.isEmpty) {
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
                      'No external products found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'External products will appear here when they are added.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: externalProducts.length,
              itemBuilder: (context, index) {
                final product = externalProducts[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(
                        Icons.shopping_bag,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      product['name'] ?? 'Unnamed Product',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product['description'] != null)
                          Text(
                            product['description'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.category, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              product['category'] ?? 'No category',
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
                          content: Text('External Product: ${product['name'] ?? 'Unnamed Product'}'),
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
