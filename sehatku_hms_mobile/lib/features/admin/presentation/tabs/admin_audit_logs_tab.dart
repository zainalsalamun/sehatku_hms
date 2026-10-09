import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/health_models.dart';
import '../../application/admin_state_providers.dart';
import '../widgets/admin_table_container.dart';

class AdminAuditLogsTab extends ConsumerStatefulWidget {
  const AdminAuditLogsTab({super.key});

  @override
  ConsumerState<AdminAuditLogsTab> createState() => _AdminAuditLogsTabState();
}

class _AdminAuditLogsTabState extends ConsumerState<AdminAuditLogsTab> {
  String _searchQuery = '';
  String _actionFilter = 'all';
  int _currentPage = 1;
  int _rowsPerPage = 10;

  final List<String> _actionOptions = [
    'all',
    'CREATE',
    'UPDATE',
    'ACTIVATE',
    'DEACTIVATE',
    'CANCEL',
    'CHECK_IN',
    'PAYMENT_SETTLE',
    'LOGIN',
  ];

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(adminAuditLogsProvider);

    final filteredLogs = logs.where((log) {
      final matchesSearch =
          log.actorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log.details.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log.resourceType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log.action.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesAction =
          _actionFilter == 'all' || log.action == _actionFilter;
      return matchesSearch && matchesAction;
    }).toList();

    final totalItems = filteredLogs.length;
    final totalPages = totalItems > 0 ? (totalItems / _rowsPerPage).ceil() : 1;
    final safePage = _currentPage > totalPages ? totalPages : (_currentPage < 1 ? 1 : _currentPage);
    final startIndex = (safePage - 1) * _rowsPerPage;
    final endIndex = math.min(startIndex + _rowsPerPage, totalItems);
    final paginatedLogs = totalItems > 0
        ? filteredLogs.sublist(startIndex, endIndex)
        : <AuditLog>[];

    final wide = MediaQuery.sizeOf(context).width > 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminTableContainer(
            title: 'Audit Trail & Keamanan Aktivitas',
            subtitle:
                'Log mutasi data immutable yang mencatat seluruh aksi create, update, deaktivasi, dan pembatalan.',
            badgeCount: logs.length,
            currentPage: safePage,
            totalItems: totalItems,
            itemsPerPage: _rowsPerPage,
            onPageChanged: (page) => setState(() => _currentPage = page),
            onItemsPerPageChanged: (count) => setState(() {
              _rowsPerPage = count;
              _currentPage = 1;
            }),
            searchHint: 'Cari aktor, resource, aksi, atau detail...',
            onSearchChanged: (val) {
              setState(() {
                _searchQuery = val;
                _currentPage = 1;
              });
            },
            filterWidget: DropdownButtonFormField<String>(
              initialValue: _actionFilter,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(),
              ),
              items: _actionOptions.map((act) {
                return DropdownMenuItem(
                  value: act,
                  child: Text(
                    act == 'all' ? 'Semua Tipe Aksi' : act,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _actionFilter = val;
                    _currentPage = 1;
                  });
                }
              },
            ),
            child: filteredLogs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'Tidak ada rekaman audit log yang sesuai filter.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : wide
                ? _buildDesktopTable(paginatedLogs)
                : _buildMobileList(paginatedLogs),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'CREATE':
        return Colors.green;
      case 'UPDATE':
        return Colors.blue;
      case 'CANCEL':
      case 'DEACTIVATE':
        return Colors.red;
      case 'ACTIVATE':
      case 'CHECK_IN':
      case 'PAYMENT_SETTLE':
        return Colors.teal;
      case 'LOGIN':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDesktopTable(List<AuditLog> logs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(Colors.grey.shade50),
        columns: const [
          DataColumn(label: Text('Timestamp & IP')),
          DataColumn(label: Text('Aktor & Role')),
          DataColumn(label: Text('Aksi')),
          DataColumn(label: Text('Resource')),
          DataColumn(label: Text('Detail Mutasi / Catatan')),
        ],
        rows: logs.map((log) {
          final color = _getActionColor(log.action);
          final timeStr =
              '${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year} ${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, "0")}';

          return DataRow(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'IP: ${log.ipAddress}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      log.actorName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      log.actorRole,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    log.action,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${log.resourceType} #${log.resourceId}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              DataCell(Text(log.details, style: const TextStyle(fontSize: 12))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList(List<AuditLog> logs) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final log = logs[index];
        final color = _getActionColor(log.action);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(Icons.security, color: color, size: 18),
          ),
          title: Text(
            '${log.actorName} • ${log.action}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${log.details}\n${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, "0")} • ${log.resourceType}',
            style: const TextStyle(fontSize: 12),
          ),
        );
      },
    );
  }
}
