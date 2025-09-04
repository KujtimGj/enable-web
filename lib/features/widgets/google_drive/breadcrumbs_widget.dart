import 'package:flutter/material.dart';
import 'package:enable_web/features/entities/google_drive.dart';

class BreadcrumbsWidget extends StatelessWidget {
  final List<Breadcrumb> breadcrumbs;
  final Function(String) onBreadcrumbTap;

  const BreadcrumbsWidget({
    super.key,
    required this.breadcrumbs,
    required this.onBreadcrumbTap,
  });

  @override
  Widget build(BuildContext context) {
    if (breadcrumbs.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.folder, size: 16, color: Colors.blue[600]),
          const SizedBox(width: 8),
          ...breadcrumbs.asMap().entries.map((entry) {
            final index = entry.key;
            final crumb = entry.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => onBreadcrumbTap(crumb.id),
                  child: Text(
                    crumb.name,
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                if (index < breadcrumbs.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
