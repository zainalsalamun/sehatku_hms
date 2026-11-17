import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../authentication/application/auth_controller.dart';
import 'tabs/admin_appointments_tab.dart';
import 'tabs/admin_audit_logs_tab.dart';
import 'tabs/admin_billing_tab.dart';
import 'tabs/admin_certificates_tab.dart';
import 'tabs/admin_doctors_tab.dart';
import 'tabs/admin_inpatient_tab.dart';
import 'tabs/admin_laboratory_tab.dart';
import 'tabs/admin_overview_tab.dart';
import 'tabs/admin_patients_tab.dart';
import 'tabs/admin_pharmacy_tab.dart';
import 'tabs/admin_procedures_tab.dart';
import 'tabs/admin_reports_tab.dart';

class _NavItem {
  const _NavItem({
    required this.tabIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.subtitle,
  });

  final int tabIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String subtitle;
}

class _NavSection {
  const _NavSection({required this.title, required this.items});

  final String title;
  final List<_NavItem> items;
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int selected = 0;
  bool _isSidebarCollapsed = false;

  static const _sections = [
    _NavSection(
      title: 'UTAMA',
      items: [
        _NavItem(
          tabIndex: 0,
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          label: 'Dashboard',
          subtitle: 'Ringkasan operasional, okupansi bed & antrean',
        ),
        _NavItem(
          tabIndex: 1,
          icon: Icons.analytics_outlined,
          activeIcon: Icons.analytics_rounded,
          label: 'Laporan Klinik',
          subtitle: 'Analitik kunjungan, pendapatan & performa poli',
        ),
      ],
    ),
    _NavSection(
      title: 'PELAYANAN KLINIS',
      items: [
        _NavItem(
          tabIndex: 5,
          icon: Icons.calendar_month_outlined,
          activeIcon: Icons.calendar_month_rounded,
          label: 'Reservasi',
          subtitle: 'Jadwal kunjungan, antrean poli & check-in pasien',
        ),
        _NavItem(
          tabIndex: 4,
          icon: Icons.people_outline,
          activeIcon: Icons.people_rounded,
          label: 'Pasien',
          subtitle: 'Direktori pasien, nomor RM & riwayat kunjungan',
        ),
        _NavItem(
          tabIndex: 3,
          icon: Icons.medical_services_outlined,
          activeIcon: Icons.medical_services_rounded,
          label: 'Dokter',
          subtitle: 'Data tenaga medis, spesialisasi & status praktik',
        ),
        _NavItem(
          tabIndex: 6,
          icon: Icons.hotel_outlined,
          activeIcon: Icons.hotel_rounded,
          label: 'Rawat Inap & Bed',
          subtitle: 'Pemetaan kamar, status bed & BOR rumah sakit',
        ),
      ],
    ),
    _NavSection(
      title: 'PENUNJANG & FARMASI',
      items: [
        _NavItem(
          tabIndex: 7,
          icon: Icons.biotech_outlined,
          activeIcon: Icons.biotech_rounded,
          label: 'Laboratorium & LIS',
          subtitle: 'Permintaan pemeriksaan lab & hasil diagnostik',
        ),
        _NavItem(
          tabIndex: 8,
          icon: Icons.local_pharmacy_outlined,
          activeIcon: Icons.local_pharmacy_rounded,
          label: 'Farmasi & Obat',
          subtitle: 'Antrean resep, racikan & stok gudang obat',
        ),
        _NavItem(
          tabIndex: 2,
          icon: Icons.healing_outlined,
          activeIcon: Icons.healing_rounded,
          label: 'Tindakan & Tarif',
          subtitle: 'Master layanan medis, poliklinik & tarif tindakan',
        ),
      ],
    ),
    _NavSection(
      title: 'ADMINISTRASI',
      items: [
        _NavItem(
          tabIndex: 9,
          icon: Icons.payments_outlined,
          activeIcon: Icons.payments_rounded,
          label: 'Kasir & Tagihan',
          subtitle: 'Pembayaran pasien, shift kasir & rekonsiliasi',
        ),
        _NavItem(
          tabIndex: 10,
          icon: Icons.description_outlined,
          activeIcon: Icons.description_rounded,
          label: 'Surat Medis',
          subtitle: 'Surat keterangan sehat, sakit & rujukan medis',
        ),
        _NavItem(
          tabIndex: 11,
          icon: Icons.history_outlined,
          activeIcon: Icons.history_rounded,
          label: 'Audit Trail',
          subtitle: 'Log aktivitas sistem & jejak perubahan data',
        ),
      ],
    ),
  ];

  static const _tabs = [
    AdminOverviewTab(),
    AdminReportsTab(),
    AdminProceduresTab(),
    AdminDoctorsTab(),
    AdminPatientsTab(),
    AdminAppointmentsTab(),
    AdminInpatientTab(),
    AdminLaboratoryTab(),
    AdminPharmacyTab(),
    AdminBillingTab(),
    AdminCertificatesTab(),
    AdminAuditLogsTab(),
  ];

  _NavItem get _currentItem {
    for (final section in _sections) {
      for (final item in section.items) {
        if (item.tabIndex == selected) return item;
      }
    }
    return _sections.first.items.first;
  }

  List<_NavItem> get _allItems =>
      _sections.expand((section) => section.items).toList();

  void _selectTab(int tabIndex) {
    setState(() => selected = tabIndex);
  }

  void _openQuickCommand() {
    showDialog<void>(
      context: context,
      builder: (ctx) => _QuickCommandDialog(
        items: _allItems,
        currentTabIndex: selected,
        onSelectTab: (index) {
          Navigator.pop(ctx);
          _selectTab(index);
        },
        onOpenQueueTv: () {
          Navigator.pop(ctx);
          context.push('/queue-display');
        },
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Konfirmasi Keluar'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari sesi Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(authControllerProvider.notifier).signOut();
              if (mounted) {
                context.go('/login');
              }
            },
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final auth = ref.watch(authControllerProvider);
    final userName = (auth.userFullName?.trim().isNotEmpty ?? false)
        ? auth.userFullName!.trim()
        : 'Budi Santoso';
    final initials = _getInitials(userName);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _openQuickCommand,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _openQuickCommand,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.background,
          drawer: !wide
              ? Drawer(
                  width: 272,
                  backgroundColor: AppColors.sidebarBg,
                  child: _buildSidebar(
                    userName: userName,
                    initials: initials,
                    collapsed: false,
                    allowCollapse: false,
                  ),
                )
              : null,
          appBar: !wide
              ? AppBar(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentItem.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(1),
                    child: Divider(height: 1),
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Cari Cepat (Ctrl+K)',
                      onPressed: _openQuickCommand,
                      icon: const Icon(Icons.search_rounded),
                    ),
                    IconButton(
                      tooltip: 'Layar TV Antrean',
                      onPressed: () => context.push('/queue-display'),
                      icon: const Icon(
                        Icons.tv_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const NotificationBellButton(),
                    const SizedBox(width: 4),
                  ],
                )
              : null,
          body: Row(
            children: [
              if (wide)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: _isSidebarCollapsed ? 76 : 252,
                  decoration: const BoxDecoration(
                    color: AppColors.sidebarBg,
                    border: Border(
                      right: BorderSide(color: AppColors.sidebarBorder),
                    ),
                  ),
                  child: _buildSidebar(
                    userName: userName,
                    initials: initials,
                    collapsed: _isSidebarCollapsed,
                    allowCollapse: true,
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (wide) _buildDesktopTopBar(userName, initials),
                    Expanded(
                      child: IndexedStack(index: selected, children: _tabs),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTopBar(String userName, String initials) {
    final current = _currentItem;

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.topBarBg,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  current.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Quick Command Search Bar
          InkWell(
            onTap: _openQuickCommand,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 240,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Cari menu atau aksi...',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Text(
                      '⌘K',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: () => context.push('/queue-display'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.sidebarActiveBorder),
              backgroundColor: AppColors.sidebarActiveBg,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.tv_rounded, size: 17),
            label: const Text(
              'TV Antrean',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 6),
          const NotificationBellButton(),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const Text(
                      'Hospital Admin',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({
    required String userName,
    required String initials,
    required bool collapsed,
    required bool allowCollapse,
  }) {
    return SafeArea(
      child: Column(
        children: [
          // Brand Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 12 : 16,
              vertical: 16,
            ),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!collapsed) ...[
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SehatKu HMS',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'Clinical & Operations',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
                if (allowCollapse && !collapsed)
                  IconButton(
                    tooltip: 'Perkecil Sidebar',
                    onPressed: () =>
                        setState(() => _isSidebarCollapsed = true),
                    icon: const Icon(
                      Icons.keyboard_double_arrow_left_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          if (allowCollapse && collapsed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: IconButton(
                tooltip: 'Perluas Sidebar',
                onPressed: () => setState(() => _isSidebarCollapsed = false),
                icon: const Icon(
                  Icons.keyboard_double_arrow_right_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          const Divider(height: 1),
          // Grouped Navigation
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: _sections.length,
              itemBuilder: (context, sectionIndex) {
                final section = _sections[sectionIndex];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!collapsed)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          18,
                          sectionIndex == 0 ? 4 : 14,
                          16,
                          6,
                        ),
                        child: Text(
                          section.title,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.grey400,
                          ),
                        ),
                      )
                    else if (sectionIndex > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Divider(height: 1),
                      ),
                    ...section.items.map((item) {
                      final isSelected = selected == item.tabIndex;
                      return _buildNavTile(item, isSelected, collapsed);
                    }),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Footer Profile & Logout
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 10 : 14,
              vertical: 12,
            ),
            child: collapsed
                ? Column(
                    children: [
                      Tooltip(
                        message: '$userName (Hospital Admin)',
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        tooltip: 'Keluar / Logout',
                        onPressed: _handleLogout,
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.error,
                          size: 19,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              'Hospital Admin • Aktif',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Keluar / Logout',
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.error,
                          size: 19,
                        ),
                        onPressed: _handleLogout,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(_NavItem item, bool isSelected, bool collapsed) {
    final tile = InkWell(
      onTap: () {
        _selectTab(item.tabIndex);
        if (MediaQuery.sizeOf(context).width < 900 &&
            Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.symmetric(
          horizontal: collapsed ? 12 : 12,
          vertical: 2,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: collapsed ? 0 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sidebarActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: AppColors.sidebarActiveBorder)
              : null,
        ),
        child: Row(
          mainAxisAlignment:
              collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            if (!collapsed && isSelected) ...[
              Container(
                width: 3,
                height: 16,
                margin: const EdgeInsets.only(right: 9),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 19,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            if (!collapsed) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isSelected ? AppColors.primaryDark : AppColors.navy,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (collapsed) {
      return Tooltip(message: item.label, child: tile);
    }
    return tile;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'AD';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

class _QuickCommandDialog extends StatefulWidget {
  const _QuickCommandDialog({
    required this.items,
    required this.currentTabIndex,
    required this.onSelectTab,
    required this.onOpenQueueTv,
  });

  final List<_NavItem> items;
  final int currentTabIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onOpenQueueTv;

  @override
  State<_QuickCommandDialog> createState() => _QuickCommandDialogState();
}

class _QuickCommandDialogState extends State<_QuickCommandDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((item) {
      if (_query.trim().isEmpty) return true;
      final q = _query.toLowerCase();
      return item.label.toLowerCase().contains(q) ||
          item.subtitle.toLowerCase().contains(q);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Ketik nama menu atau modul...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ...filtered.map((item) {
                    final isCurrent = item.tabIndex == widget.currentTabIndex;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        item.activeIcon,
                        color: isCurrent
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                      subtitle: Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      trailing: isCurrent
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Aktif',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            )
                          : null,
                      onTap: () => widget.onSelectTab(item.tabIndex),
                    );
                  }),
                  if (_query.isEmpty ||
                      'tv antrean display'.contains(_query.toLowerCase()))
                    ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.tv_rounded,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Buka Layar Display TV Antrean',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                      subtitle: const Text(
                        'Tampilkan antrean ruang tunggu secara penuh',
                        style: TextStyle(fontSize: 11.5),
                      ),
                      onTap: widget.onOpenQueueTv,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
