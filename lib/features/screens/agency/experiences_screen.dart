import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:enable_web/features/components/responsive_scaffold.dart';
import 'package:enable_web/features/providers/agencyProvider.dart';
import 'package:enable_web/features/providers/userProvider.dart';

class ExperiencesScreen extends StatefulWidget {
  const ExperiencesScreen({super.key});

  @override
  State<ExperiencesScreen> createState() => _ExperiencesScreenState();
}

class _ExperiencesScreenState extends State<ExperiencesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Experiences',
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
            if (agencyId != null && agencyProvider.experiences.isEmpty && !agencyProvider.isLoadingData) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                agencyProvider.fetchExperiences(agencyId!);
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
                      'Error loading experiences',
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
                          agencyProvider.fetchExperiences(agencyId!);
                        }
                      },
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final experiences = agencyProvider.experiences;

            if (experiences.isEmpty) {
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
                      'No experiences found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Experiences will appear here when they are added.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: experiences.length,
              itemBuilder: (context, index) {
                final experience = experiences[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: Icon(
                        Icons.explore,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      experience['title'] ?? 'Unnamed Experience',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (experience['description'] != null)
                          Text(
                            experience['description'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              experience['location'] ?? 'Location not specified',
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
                          content: Text('Experience: ${experience['title'] ?? 'Unnamed Experience'}'),
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
