import 'package:flutter/material.dart';
import 'package:enable_web/core/responsive_utils.dart';
import 'package:enable_web/features/components/responsive_scaffold.dart';
import 'package:enable_web/features/components/responsive_grid.dart';
import 'package:enable_web/features/components/responsive_navigation.dart';
import 'package:enable_web/features/controllers/user_controller.dart';
import 'package:enable_web/features/entities/user.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userController = Provider.of<UserController>(context, listen: false);
      // You'll need to get the agency ID from your auth provider or stored data
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: ResponsiveAppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(
            fontSize: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 20,
              tablet: 24,
              desktop: 28,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildDashboardContent(context),
    );
  }

  Widget  _buildDashboardContent(BuildContext context) {
    return ResponsiveContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 16, tablet: 24, desktop: 32)),
            Consumer<UserController>(
              builder: (context, userController, child) {
                return ResponsiveCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'User Management',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.responsiveFontSize(
                                context,
                                mobile: 20,
                                tablet: 24,
                                desktop: 28,
                              ),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                  
                    ],
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back!',
            style: TextStyle(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 24,
                tablet: 28,
                desktop: 32,
              ),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
          Text(
            'Here\'s what\'s happening with your account today.',
            style: TextStyle(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
              color: const Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, Map<String, dynamic> stat) {
    return ResponsiveCard(
      color: Color(0xff363636),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                stat['icon'] as IconData,
                color: stat['color'] as Color,
                size: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 24,
                  tablet: 28,
                  desktop: 32,
                ),
              ),
              Icon(
                Icons.trending_up,
                color: Colors.green,
                size: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
          Text(
            stat['value'] as String,
            style: TextStyle(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 24,
                tablet: 28,
                desktop: 32,
              ),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 4, tablet: 6, desktop: 8)),
          Text(
            stat['title'] as String,
            style: TextStyle(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 12,
                tablet: 14,
                desktop: 16,
              ),
              color: const Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildUserCard(BuildContext context, UserModel user) {
    return ResponsiveCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 2, tablet: 4, desktop: 6)),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                    color: const Color(0xFF999999),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 2, tablet: 4, desktop: 6)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.responsiveSpacing(context, mobile: 6, tablet: 8, desktop: 10),
                    vertical: ResponsiveUtils.responsiveSpacing(context, mobile: 2, tablet: 4, desktop: 6),
                  ),
                  decoration: BoxDecoration(
                    color: user.role == 'full' ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.role == 'full' ? 'Full Access' : 'Partial Access',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 10,
                        tablet: 12,
                        desktop: 14,
                      ),
                      color: user.role == 'full' ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveUtils.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
          // Access change buttons
          Column(
            children: [
              _buildAccessButton(
                context, 
                user, 
                'Full Access', 
                'full', 
                Colors.green,
                Icons.security,
              ),
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, mobile: 4, tablet: 6, desktop: 8)),
              _buildAccessButton(
                context, 
                user, 
                'Partial Access', 
                'partial', 
                Colors.orange,
                Icons.person_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessButton(BuildContext context, UserModel user, String label, String role, Color color, IconData icon,) {
    final isCurrentRole = user.role == role;

    return SizedBox(
      width: ResponsiveUtils.responsiveFontSize(
        context,
        mobile: 80,
        tablet: 100,
        desktop: 120,
      ),
      height: ResponsiveUtils.responsiveFontSize(
        context,
        mobile: 32,
        tablet: 36,
        desktop: 40,
      ),
      child: ElevatedButton(
        onPressed: isCurrentRole ? null : () {
          // Button functionality will be added later
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label Access button clicked for ${user.name}'),
              backgroundColor: Colors.blue,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrentRole ? color.withOpacity(0.3) : color.withOpacity(0.1),
          foregroundColor: isCurrentRole ? color : Colors.white,
          side: BorderSide(
            color: isCurrentRole ? color : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.responsiveSpacing(context, mobile: 4, tablet: 6, desktop: 8),
          ),
        ),
        child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.responsiveSpacing(context, mobile: 2, tablet: 4, desktop: 6)),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          context,
                          mobile: 8,
                          tablet: 10,
                          desktop: 12,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }


} 