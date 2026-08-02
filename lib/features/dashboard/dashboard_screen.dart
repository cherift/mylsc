import 'package:fleet_manager/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/i18n/app_localizations.dart';


/// Dashboard principal de l'application
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar pour tablette
          if (isTablet) _buildSidebar(),

          // Contenu principal
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeSection(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildStatsGrid(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Bottom navigation pour mobile
      bottomNavigationBar: isTablet ? null : _buildBottomNav(),
    );
  }

  /// Sidebar de navigation
  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          right: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Iconsax.truck_fast,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Text(
                  'My LSC',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.surfaceBorder),

          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              children: [
                _buildNavItem(0, Iconsax.home_25, context),
                _buildNavItem(1, Iconsax.truck, context),
                _buildNavItem(2, Iconsax.map5, context),
                _buildNavItem(3, Iconsax.status5, context),
                _buildNavItem(4, Iconsax.calendar5, context),
                _buildNavItem(5, Iconsax.chart_25, context),
                _buildNavItem(6, Iconsax.notification5, context),
                const SizedBox(height: AppSpacing.lg),
                const Divider(color: AppColors.surfaceBorder),
                const SizedBox(height: AppSpacing.lg),
                _buildNavItem(7, Iconsax.setting_25, context),
                _buildNavItem(8, Iconsax.message_question5, context),
              ],
            ),
          ),

          // Profil utilisateur
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.surfaceBorder),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: const Center(
                    child: Text(
                      'JD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jean Dupont',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Administrateur',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.logout, size: 20),
                  color: AppColors.textTertiary,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, BuildContext context) {
    final isSelected = _selectedIndex == index;
    final l10n = AppLocalizations.of(context);

    // Map index to translation key
    final labels = [
      l10n.dashboardHome,         // 0
      l10n.dashboardVehicles,     // 1
      l10n.dashboardMap,          // 2
      l10n.dashboardFleets,       // 3
      l10n.dashboardPlanning,     // 4
      l10n.dashboardReports,      // 5
      l10n.dashboardAlerts,       // 6
      l10n.commonSettings,        // 7
      l10n.dashboardHelp,         // 8
    ];

    final label = labels[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color:
                  isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: isSelected
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color:
                      isSelected ? AppColors.primary : AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header du dashboard
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: const Row(
                children: [
                  SizedBox(width: AppSpacing.md),
                  Icon(Iconsax.search_normal,
                      size: 20, color: AppColors.textTertiary),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          _buildHeaderIcon(Iconsax.notification, badge: 3),
          const SizedBox(width: AppSpacing.sm),
          _buildHeaderIcon(Iconsax.message),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {int? badge}) {
    return Stack(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
        if (badge != null)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                badge.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  /// Section de bienvenue
  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bonjour, Jean 👋',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Voici l\'aperçu de votre flotte aujourd\'hui',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideX(begin: -0.1),
      ],
    );
  }

  /// Grille de statistiques
  Widget _buildStatsGrid() {
    final stats = [
      _StatData(
          'Véhicules actifs', '24', '+2', Iconsax.truck, AppColors.primary),
      _StatData('En transit', '18', '+5', Iconsax.routing5, AppColors.success),
      _StatData(
          'En maintenance', '3', '-1', Iconsax.setting_45, AppColors.warning),
      _StatData('Alertes', '7', '+3', Iconsax.danger5, AppColors.error),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.8,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return _buildStatCard(stats[index])
            .animate()
            .fadeIn(
                duration: 500.ms, delay: Duration(milliseconds: 100 * index))
            .slideY(begin: 0.2);
      },
    );
  }

  Widget _buildStatCard(_StatData stat) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(stat.icon, size: 20, color: stat.color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: stat.change.startsWith('+')
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  stat.change,
                  style: TextStyle(
                    color: stat.change.startsWith('+')
                        ? AppColors.success
                        : AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                stat.label,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Actions rapides
  Widget _buildQuickActions() {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dashboardQuickActions,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _buildActionButton(
                Iconsax.add, l10n.dashboardNewVehicle, AppColors.primary),
            _buildActionButton(
                Iconsax.category_2, l10n.dashboardCreateFleet, AppColors.success),
            _buildActionButton(
                Iconsax.calendar_add, l10n.dashboardPlanRoute, AppColors.accent),
            _buildActionButton(
                Iconsax.document, l10n.dashboardGenerateReport, AppColors.info),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  /// Bottom navigation pour mobile
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(0, Iconsax.home_25, context),
              _buildBottomNavItem(1, Iconsax.truck, context),
              _buildBottomNavItem(2, Iconsax.map5, context),
              _buildBottomNavItem(3, Iconsax.notification5, context),
              _buildBottomNavItem(4, Iconsax.setting_25, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon, BuildContext context) {
    final isSelected = _selectedIndex == index;
    final l10n = AppLocalizations.of(context);

    // Map index to translation key for bottom nav
    final labels = [
      l10n.dashboardHome,         // 0
      l10n.dashboardVehicles,     // 1
      l10n.dashboardMap,          // 2
      l10n.dashboardAlerts,       // 3
      'Plus',                     // 4 - Temporaire
    ];

    final label = labels[index];

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected ? AppColors.primary : AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  _StatData(this.label, this.value, this.change, this.icon, this.color);
  final String label;
  final String value;
  final String change;
  final IconData icon;
  final Color color;
}
