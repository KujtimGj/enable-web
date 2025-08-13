import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:enable_web/features/components/responsive_scaffold.dart';
import 'package:enable_web/features/providers/agencyProvider.dart';
import 'package:enable_web/features/providers/userProvider.dart';

class DMCListScreen extends StatefulWidget {
  const DMCListScreen({super.key});

  @override
  State<DMCListScreen> createState() => _DMCListScreenState();
}

class _DMCListScreenState extends State<DMCListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DMC Documents',
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
            if (agencyId != null && agencyProvider.dmcs.isEmpty && !agencyProvider.isLoadingData) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                agencyProvider.fetchDMCs(agencyId!);
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
                      'Error loading DMC documents',
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
                          agencyProvider.fetchDMCs(agencyId!);
                        }
                      },
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final dmcs = agencyProvider.dmcs;

            if (dmcs.isEmpty) {
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
                      'No DMC documents found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'DMC documents will appear here when they are added.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: dmcs.length,
              itemBuilder: (context, index) {
                final dmc = dmcs[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.business,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      dmc['name'] ?? 'Unnamed DMC',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dmc['description'] != null)
                          Text(
                            dmc['description'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              dmc['location'] ?? 'Location not specified',
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
                          content: Text('DMC: ${dmc['name'] ?? 'Unnamed DMC'}'),
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
