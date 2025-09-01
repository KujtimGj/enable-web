import 'package:enable_web/features/components/chat_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive_utils.dart';
import '../../components/responsive_scaffold.dart';
import '../../components/widgets.dart';
import '../../providers/vicProvider.dart';
import '../../providers/agencyProvider.dart';
import '../../entities/vicModel.dart';

class VICs extends StatefulWidget {
  const VICs({super.key});

  @override
  State<VICs> createState() => _VICsState();
}

class _VICsState extends State<VICs> {
  @override
  void initState() {
    super.initState();
    // Fetch VICs when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vicProvider = Provider.of<VICProvider>(context, listen: false);
      final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
      if (agencyProvider.agency?.id != null) {
        vicProvider.fetchVICsByAgencyId(agencyProvider.agency!.id!);
      }
    });
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
              Text("VICs", style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        centerTitle: true,
        title: customForm(context),
        actions: [customButton((){context.go("/");})],
      ),
      body: ResponsiveContainer(
        child: Row(
          children: [
            bottomLeftBar(),
            Expanded(
              flex: 1,
              child: Stack(
                children: [
                  Consumer<VICProvider>(
                    builder: (context, vicProvider, child) {
                      if (vicProvider.isLoading) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading VICs...'),
                            ],
                          ),
                        );
                      }

                      if (vicProvider.errorMessage != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.red),
                              SizedBox(height: 16),
                              Text(
                                'Error: ${vicProvider.errorMessage}',
                                style: TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  final vicProvider = Provider.of<VICProvider>(context, listen: false);
                                  final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
                                  if (agencyProvider.agency?.id != null) {
                                    vicProvider.fetchVICsByAgencyId(agencyProvider.agency!.id!);
                                  }
                                },
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final vics = vicProvider.vics;
                      
                      if (vics.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No VICs found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No VICs found for this agency',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                        );
                      }

                      return Container(
                        padding: EdgeInsets.all(10),
                        child: RefreshIndicator(
                          onRefresh: () async {
                            final vicProvider = Provider.of<VICProvider>(context, listen: false);
                            final agencyProvider = Provider.of<AgencyProvider>(context, listen: false);
                            if (agencyProvider.agency?.id != null) {
                              await vicProvider.fetchVICsByAgencyId(agencyProvider.agency!.id!);
                            }
                          },
                          child: GridView.builder(
                            shrinkWrap: false,
                            physics: AlwaysScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                              ResponsiveUtils.isMobile(context)
                                  ? 1
                                  : ResponsiveUtils.isTablet(context)
                                  ? 2
                                  : 3,
                              childAspectRatio: 2,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 20,
                            ),
                            itemCount: vics.length,
                            itemBuilder: (BuildContext context, int index) {
                              final vic = vics[index];
                              return _buildVICCard(vic, index);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVICCard(VICModel vic, int index) {
    return GestureDetector(
      onTap: () {
        _showVICDetails(context, vic);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        width: 30,
                        decoration: BoxDecoration(
                          color: Color(0xff292525),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/chat.svg',
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        vic.fullName ?? 'VIC ${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      if (vic.nationality != null) ...[
                        Text(
                          vic.nationality!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                      ],
                      if (vic.email != null) ...[
                        Text(
                          vic.email!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                      ],
                      if (vic.summary != null && vic.summary!.isNotEmpty) ...[
                        Text(
                          vic.summary!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        Text(
                          'No description available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
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

  void _showVICDetails(BuildContext context, VICModel vic) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(vic.fullName ?? 'VIC Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (vic.email != null) ...[
                  Text('Email: ${vic.email}'),
                  SizedBox(height: 8),
                ],
                if (vic.phone != null) ...[
                  Text('Phone: ${vic.phone}'),
                  SizedBox(height: 8),
                ],
                if (vic.nationality != null) ...[
                  Text('Nationality: ${vic.nationality}'),
                  SizedBox(height: 8),
                ],
                if (vic.summary != null && vic.summary!.isNotEmpty) ...[
                  Text('Summary: ${vic.summary}'),
                  SizedBox(height: 8),
                ],
                if (vic.preferences != null && vic.preferences!.isNotEmpty) ...[
                  Text('Preferences: ${vic.preferences}'),
                  SizedBox(height: 8),
                ],
                if (vic.createdAt != null) ...[
                  Text('Created: ${_formatDate(vic.createdAt!)}'),
                  SizedBox(height: 8),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
