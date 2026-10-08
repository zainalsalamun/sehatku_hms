import 'package:flutter/material.dart';
import '../../../../shared/widgets/admin_pagination_footer.dart';

class AdminTableContainer extends StatelessWidget {
  const AdminTableContainer({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.searchHint = 'Cari data...',
    this.onSearchChanged,
    this.filterWidget,
    this.actionLabel,
    this.actionIcon,
    this.onActionPressed,
    this.badgeCount,
    this.currentPage,
    this.totalItems,
    this.itemsPerPage = 10,
    this.onPageChanged,
    this.onItemsPerPageChanged,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final Widget? filterWidget;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onActionPressed;
  final int? badgeCount;

  // Pagination support
  final int? currentPage;
  final int? totalItems;
  final int itemsPerPage;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<int>? onItemsPerPageChanged;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 800;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: wide
                ? Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (badgeCount != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$badgeCount total',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (actionLabel != null && onActionPressed != null)
                        FilledButton.icon(
                          onPressed: onActionPressed,
                          icon: Icon(actionIcon ?? Icons.add, size: 18),
                          label: Text(actionLabel!),
                        ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (badgeCount != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$badgeCount',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 13,
                        ),
                      ),
                      if (actionLabel != null && onActionPressed != null) ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: onActionPressed,
                          icon: Icon(actionIcon ?? Icons.add, size: 18),
                          label: Text(actionLabel!),
                        ),
                      ],
                    ],
                  ),
          ),
          const Divider(height: 1),

          // Search & Filter Toolbar
          if (onSearchChanged != null || filterWidget != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: wide
                  ? Row(
                      children: [
                        if (onSearchChanged != null)
                          Expanded(
                            flex: 3,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: searchHint,
                                prefixIcon: const Icon(Icons.search, size: 20),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: onSearchChanged,
                            ),
                          ),
                        if (onSearchChanged != null && filterWidget != null)
                          const SizedBox(width: 16),
                        if (filterWidget != null)
                          Expanded(flex: 2, child: filterWidget!),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (onSearchChanged != null)
                          TextField(
                            decoration: InputDecoration(
                              hintText: searchHint,
                              prefixIcon: const Icon(Icons.search, size: 20),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: onSearchChanged,
                          ),
                        if (filterWidget != null) ...[
                          const SizedBox(height: 8),
                          filterWidget!,
                        ],
                      ],
                    ),
            ),

          // Content / Table View
          child,

          // Optional Pagination Footer
          if (currentPage != null && totalItems != null && onPageChanged != null)
            AdminPaginationFooter(
              currentPage: currentPage!,
              totalItems: totalItems!,
              itemsPerPage: itemsPerPage,
              onPageChanged: onPageChanged!,
              onItemsPerPageChanged: onItemsPerPageChanged,
            ),
        ],
      ),
    );
  }
}
