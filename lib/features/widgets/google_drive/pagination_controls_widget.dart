import 'package:flutter/material.dart';
import 'package:enable_web/features/entities/google_drive.dart';

class PaginationControlsWidget extends StatelessWidget {
  final PaginationInfo? pagination;
  final bool isLoadingMore;
  final Function(int) onPageChange;
  final Function(int)? onPageSizeChange;

  const PaginationControlsWidget({
    super.key,
    required this.pagination,
    required this.isLoadingMore,
    required this.onPageChange,
    this.onPageSizeChange,
  });

  @override
  Widget build(BuildContext context) {
    if (pagination == null) return const SizedBox.shrink();
    
    final totalPages = pagination!.totalPages;
    
    if (totalPages <= 1) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page info
          Text(
            'Page ${pagination!.currentPage} of $totalPages (${pagination!.totalItems} total items)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          
          // Page size selector
          Row(
            children: [
              // Page size dropdown
              if (onPageSizeChange != null) ...[
                Text(
                  'Show:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 4),
                DropdownButton<int>(
                  value: pagination!.pageSize,
                  items: const [
                    DropdownMenuItem(value: 50, child: Text('50')),
                    DropdownMenuItem(value: 100, child: Text('100')),
                    DropdownMenuItem(value: 200, child: Text('200')),
                    DropdownMenuItem(value: 500, child: Text('500')),
                  ],
                  onChanged: isLoadingMore ? null : (value) {
                    if (value != null) {
                      onPageSizeChange!(value);
                    }
                  },
                  underline: const SizedBox(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                  ),
                ),
                const SizedBox(width: 16),
              ],
              // First page
              IconButton(
                onPressed: (isLoadingMore || pagination!.currentPage <= 1)
                    ? null
                    : () => onPageChange(1),
                icon: isLoadingMore && pagination!.currentPage > 1
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.first_page, size: 20),
                tooltip: 'First page',
                color: (isLoadingMore || pagination!.currentPage <= 1) ? Colors.grey[400] : Colors.blue[600],
              ),
              
              // Previous page
              IconButton(
                onPressed: (isLoadingMore || pagination!.currentPage <= 1)
                    ? null
                    : () => onPageChange(pagination!.currentPage - 1),
                icon: isLoadingMore && pagination!.currentPage > 1
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_left, size: 20),
                tooltip: 'Previous page',
                color: (isLoadingMore || pagination!.currentPage <= 1) ? Colors.grey[400] : Colors.blue[600],
              ),
              
              // Current page indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: isLoadingMore
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${pagination!.currentPage}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        '${pagination!.currentPage}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              
              // Next page
              IconButton(
                onPressed: (isLoadingMore || pagination!.currentPage >= totalPages)
                    ? null
                    : () => onPageChange(pagination!.currentPage + 1),
                icon: isLoadingMore && pagination!.currentPage < totalPages
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right, size: 20),
                tooltip: 'Next page',
                color: (isLoadingMore || pagination!.currentPage >= totalPages) ? Colors.grey[400] : Colors.blue[600],
              ),
              
              // Last page
              IconButton(
                onPressed: (isLoadingMore || pagination!.currentPage >= totalPages)
                    ? null
                    : () => onPageChange(totalPages),
                icon: isLoadingMore && pagination!.currentPage < totalPages
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.last_page, size: 20),
                tooltip: 'Last page',
                color: (isLoadingMore || pagination!.currentPage >= totalPages) ? Colors.grey[400] : Colors.blue[600],
              ),
              
              // Page input for large page counts
              if (totalPages > 20) ...[
                const SizedBox(width: 8),
                Text(
                  'Go to:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 60,
                  height: 32,
                  child: TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '${pagination!.currentPage}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 12),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        final pageNum = int.tryParse(value);
                        if (pageNum != null && pageNum >= 1 && pageNum <= totalPages && pageNum != pagination!.currentPage) {
                          onPageChange(pageNum);
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'of $totalPages',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
