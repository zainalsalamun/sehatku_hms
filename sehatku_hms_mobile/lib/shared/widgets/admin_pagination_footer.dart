import 'package:flutter/material.dart';

class AdminPaginationFooter extends StatelessWidget {
  const AdminPaginationFooter({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
    this.onItemsPerPageChanged,
    this.itemsPerPageOptions = const [5, 10, 20, 50],
  });

  final int currentPage;
  final int totalItems;
  final int itemsPerPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onItemsPerPageChanged;
  final List<int> itemsPerPageOptions;

  int get totalPages => totalItems == 0 ? 1 : (totalItems / itemsPerPage).ceil();
  int get startItem => totalItems == 0 ? 0 : (currentPage - 1) * itemsPerPage + 1;
  int get endItem => (currentPage * itemsPerPage).clamp(0, totalItems);

  @override
  Widget build(BuildContext context) {
    if (totalItems == 0) return const SizedBox.shrink();

    final wide = MediaQuery.sizeOf(context).width > 700;

    final infoText = Text(
      'Menampilkan $startItem - $endItem dari $totalItems data',
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w500,
      ),
    );

    final perPageSelector = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Baris per halaman:',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: itemsPerPageOptions.contains(itemsPerPage)
              ? itemsPerPage
              : itemsPerPageOptions.first,
          underline: const SizedBox(),
          isDense: true,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          items: itemsPerPageOptions.map((opt) {
            return DropdownMenuItem<int>(
              value: opt,
              child: Text('$opt'),
            );
          }).toList(),
          onChanged: onItemsPerPageChanged != null
              ? (val) {
                  if (val != null) onItemsPerPageChanged!(val);
                }
              : null,
        ),
      ],
    );

    final paginationButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.first_page, size: 20),
          tooltip: 'Halaman Pertama',
          onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 20),
          tooltip: 'Halaman Sebelumnya',
          onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$currentPage / $totalPages',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 20),
          tooltip: 'Halaman Berikutnya',
          onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
        ),
        IconButton(
          icon: const Icon(Icons.last_page, size: 20),
          tooltip: 'Halaman Terakhir',
          onPressed: currentPage < totalPages ? () => onPageChanged(totalPages) : null,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: wide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    infoText,
                    if (onItemsPerPageChanged != null) ...[
                      const SizedBox(width: 24),
                      perPageSelector,
                    ],
                  ],
                ),
                paginationButtons,
              ],
            )
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    infoText,
                    if (onItemsPerPageChanged != null) perPageSelector,
                  ],
                ),
                const SizedBox(height: 8),
                Center(child: paginationButtons),
              ],
            ),
    );
  }
}
