import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/domain/models/permission.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../trucks/presentation/screens/truck_management_screen.dart';
import '../../../users/presentation/screens/user_management_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../fuel/presentation/screens/fuel_attendant_screen.dart';
import '../../../fuel/presentation/screens/fuel_supply_manager_screen.dart';
import '../../../weighing/presentation/screens/unified_weighing_screen.dart';
import '../../../weighing/domain/models/weighing_record_model.dart';
import '../../../breakdown/presentation/screens/technical_center_screen.dart';
import '../../../chauffeur/presentation/screens/driver_list_screen.dart';
import '../../../fleet/presentation/screens/fleet_list_screen.dart';
import '../../../fleet_supervisor/presentation/screens/fleet_supervisor_dashboard_screen.dart';
import '../../../general_supervisor/presentation/screens/general_supervisor_screen.dart';
import '../../../operations/presentation/screens/operations_manager_screen.dart';
import '../../../users/presentation/widgets/managed_employees_widget.dart';
import '../widgets/direction_dashboard.dart';
import '../../../statistics/presentation/screens/fleet_statistics_screen.dart';
import '../../../fuel/presentation/screens/ravitaillement_screen.dart';
import '../../../storage/presentation/screens/storage_supervisor_screen.dart';

// ─── Nav item data ────────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.pageIndex,
    this.onTapExtra,
  });

  final IconData icon;
  final String label;
  final int pageIndex;
  final VoidCallback? onTapExtra;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

/// Écran principal du tableau de bord avec navigation responsive :
/// - Mobile  : Drawer + AppBar hamburger
/// - Tablet  : NavigationRail latérale compacte
/// - Desktop : Sidebar pleine largeur (comportement d'origine)
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  int _fleetSupervisorKey = 0;

  // ─── Build nav items (role-dependent) ──────────────────────────────────────

  List<_NavItem> _navItems(UserModel user) {
    final l10n = AppLocalizations.of(context);
    final roleKey = user.role?.toLowerCase().replaceAll(' ', '');
    final isSupervisorFlotte = roleKey == 'superviseurflotte';

    final items = <_NavItem>[
      _NavItem(
        icon: Iconsax.home,
        label: l10n.translate('dashboard.home'),
        pageIndex: 0,
      ),
    ];

    if (!isSupervisorFlotte) {
      items.addAll([
        _NavItem(
          icon: Iconsax.chart_21,
          label: l10n.translate('statistics.title'),
          pageIndex: 9,
        ),
        _NavItem(
          icon: Iconsax.gas_station,
          label: l10n.translate('ravitaillement.title'),
          pageIndex: 10,
        ),
        _NavItem(
          icon: Iconsax.truck_fast,
          label: l10n.translate('fleet.title'),
          pageIndex: 6,
        ),
        _NavItem(
          icon: Iconsax.truck,
          label: l10n.translate('dashboard.vehicles'),
          pageIndex: 1,
        ),
        _NavItem(
          icon: Iconsax.driver,
          label: l10n.translate('dashboard.drivers'),
          pageIndex: 2,
        ),
        _NavItem(
          icon: Iconsax.location,
          label: l10n.translate('dashboard.gpsTracking'),
          pageIndex: 3,
        ),
        _NavItem(
          icon: Iconsax.people,
          label: l10n.translate('management.title'),
          pageIndex: 8,
        ),
      ]);
    }

    if (isSupervisorFlotte) {
      items.addAll([
        _NavItem(
          icon: Iconsax.truck_fast,
          label: l10n.translate('fleet.myFleets'),
          pageIndex: 7,
          onTapExtra: () => setState(() => _fleetSupervisorKey++),
        ),
        _NavItem(
          icon: Iconsax.chart_square,
          label: l10n.translate('statistics.title'),
          pageIndex: 9,
        ),
        _NavItem(
          icon: Iconsax.people,
          label: l10n.translate('management.managedEmployees'),
          pageIndex: 8,
        ),
      ]);
    }

    if (user.hasPermission(Permission.viewUsers)) {
      items.add(_NavItem(
        icon: Iconsax.people,
        label: l10n.translate('dashboard.userManagement'),
        pageIndex: 4,
      ));
    }

    items.add(_NavItem(
      icon: Iconsax.setting_2,
      label: l10n.translate('dashboard.settings'),
      pageIndex: 5,
    ));

    return items;
  }

  // ─── Main build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UserModel?>>(authControllerProvider, (previous, next) {
      next.whenData((user) {
        if (user == null) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
    });

    final authState = ref.watch(authControllerProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        // Rôles avec écran dédié (pas de shell de navigation)
        final roleKey = user.role?.toLowerCase().replaceAll(' ', '');
        if (roleKey == 'pompiste') return const FuelAttendantScreen();
        if (roleKey == 'chefravitaillement') return const FuelSupplyManagerScreen();
        if (roleKey == 'superviseurgeneral') return const GeneralSupervisorScreen();
        if (roleKey == 'responsableoperations') return const OperationsManagerScreen();
        if (roleKey == 'superviseurmine') {
          return const UnifiedWeighingScreen(defaultLocation: WeighingLocation.mine);
        }
        if (roleKey == 'superviseurport') {
          return const UnifiedWeighingScreen(defaultLocation: WeighingLocation.port);
        }
        if (roleKey == 'superviseurstockage') {
          return const StorageSupervisorScreen();
        }
        if (roleKey == 'centretechnique') return const TechnicalCenterScreen();

        // Shell responsive
        return _buildResponsiveShell(user);
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Erreur: $error',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  // ─── Responsive shell ──────────────────────────────────────────────────────

  Widget _buildResponsiveShell(UserModel user) {
    if (context.isMobile) return _buildMobileShell(user);
    if (context.isTablet) return _buildTabletShell(user);
    return _buildDesktopShell(user);
  }

  /// Mobile : AppBar + Drawer hamburger
  Widget _buildMobileShell(UserModel user) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildMobileAppBar(user),
      drawer: Drawer(
        backgroundColor: AppColors.backgroundSecondary,
        child: _buildSidebarContent(user),
      ),
      body: _buildMainContent(user),
    );
  }

  /// Tablet : Sidebar compacte (même layout que desktop, textes réduits)
  Widget _buildTabletShell(UserModel user) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 210,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.backgroundSecondary,
                border: Border(right: BorderSide(color: AppColors.surfaceBorder)),
              ),
              child: _buildSidebarContent(user, compact: true),
            ),
          ),
          Expanded(child: _buildMainContent(user)),
        ],
      ),
    );
  }

  /// Desktop : Sidebar pleine largeur (comportement d'origine)
  Widget _buildDesktopShell(UserModel user) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 260,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.backgroundSecondary,
                border: Border(right: BorderSide(color: AppColors.surfaceBorder)),
              ),
              child: _buildSidebarContent(user),
            ),
          ),
          Expanded(child: _buildMainContent(user)),
        ],
      ),
    );
  }

  // ─── Sidebar content (partagé drawer + desktop) ────────────────────────────

  Widget _buildSidebarContent(UserModel user, {bool compact = false}) {
    return Column(
      children: [
        _buildSidebarHeader(user, compact: compact),
        Expanded(child: _buildNavigationMenu(user, compact: compact)),
        _buildLogoutButton(compact: compact),
      ],
    );
  }

  Widget _buildSidebarHeader(UserModel user, {bool compact = false}) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Iconsax.truck_fast, color: Colors.white, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('dashboard.appName'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.translate('dashboard.dashboardTitle'),
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName.isEmpty ? user.email : user.fullName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.role != null)
                        Text(
                          user.role!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationMenu(UserModel user, {bool compact = false}) {
    final l10n = AppLocalizations.of(context);
    final items = _navItems(user);
    final roleKey = user.role?.toLowerCase().replaceAll(' ', '');
    final isSupervisorFlotte = roleKey == 'superviseurflotte';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        for (int i = 0; i < items.length; i++) ...[
          // Section header avant "Administration"
          if (!isSupervisorFlotte &&
              items[i].pageIndex == 4 &&
              user.hasPermission(Permission.viewUsers)) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                l10n.translate('dashboard.administration'),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          // Section header avant "Paramètres"
          if (items[i].pageIndex == 5) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                l10n.translate('dashboard.general'),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          _buildNavItem(items[i], compact: compact),
          if (i < items.length - 1) const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }

  Widget _buildNavItem(_NavItem item, {bool compact = false}) {
    final isSelected = _selectedIndex == item.pageIndex;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _selectedIndex = item.pageIndex);
          item.onTapExtra?.call();
          // Fermer le drawer sur mobile
          if (context.isMobile && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: compact ? AppSpacing.sm : AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: compact ? 18 : 20,
              ),
              SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontSize: compact ? 12 : 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton({bool compact = false}) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _signOut,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: compact ? AppSpacing.sm : AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(Iconsax.logout, color: AppColors.error, size: compact ? 18 : 20),
                SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
                Text(
                  l10n.authLogout,
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Mobile AppBar ─────────────────────────────────────────────────────────

  PreferredSizeWidget _buildMobileAppBar(UserModel user) {
    final l10n = AppLocalizations.of(context);
    return AppBar(
      backgroundColor: AppColors.backgroundSecondary,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textPrimary),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: Image.asset(
              'assets/images/logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: const Icon(Iconsax.truck_fast, color: Colors.white, size: 14),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.translate('dashboard.appName'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.surfaceBorder),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) {
      await Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Widget _buildMainContent(UserModel user) {
    switch (_selectedIndex) {
      case 0:
        return DirectionDashboard(user: user);
      case 1:
        return const TruckManagementScreen();
      case 2:
        return const DriverListScreen();
      case 4:
        return const UserManagementScreen();
      case 5:
        return const SettingsScreen();
      case 6:
        return const FleetListScreen();
      case 7:
        return FleetSupervisorDashboardScreen(key: ValueKey(_fleetSupervisorKey));
      case 8:
        return const ManagedEmployeesWidget();
      case 9:
        return const FleetStatisticsScreen();
      case 10:
        return const RavitaillementScreen();
      default:
        final l10n = AppLocalizations.of(context);
        return Center(
          child: Text(
            l10n.translate('dashboard.sectionInDevelopment'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        );
    }
  }
}
