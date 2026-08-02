import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../trucks/domain/models/truck_model.dart';
import '../../../weighing/presentation/providers/weighing_providers.dart';

/// Écran du superviseur stockage — sections Déchargé et Chargé
class StorageSupervisorScreen extends ConsumerStatefulWidget {
  const StorageSupervisorScreen({super.key});

  @override
  ConsumerState<StorageSupervisorScreen> createState() =>
      _StorageSupervisorScreenState();
}

class _StorageSupervisorScreenState
    extends ConsumerState<StorageSupervisorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final l10n = AppLocalizations.of(context);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (_showSettings) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.backgroundSecondary,
              leading: IconButton(
                icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
                onPressed: () => setState(() => _showSettings = false),
              ),
              title: Text(
                l10n.translate('settings.title'),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
            body: const SettingsScreen(),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(Iconsax.box, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.translate('storage.title'),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              user.fullName.isEmpty ? user.email : user.fullName,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _showSettings = true),
                        icon: const Icon(Iconsax.setting_2, color: AppColors.textSecondary),
                      ),
                      IconButton(
                        onPressed: () async {
                          final nav = Navigator.of(context);
                          await ref.read(authControllerProvider.notifier).signOut();
                          if (!mounted) return;
                          await nav.pushReplacementNamed('/login');
                        },
                        icon: const Icon(Iconsax.logout, color: AppColors.error),
                      ),
                    ],
                  ),
                ),
                // Tabs
                Container(
                  color: AppColors.backgroundSecondary,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    tabs: [
                      Tab(
                        icon: const Icon(Iconsax.arrow_down),
                        text: l10n.translate('storage.unloaded'),
                      ),
                      Tab(
                        icon: const Icon(Iconsax.arrow_up),
                        text: l10n.translate('storage.loaded'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _StorageTab(
                        eventType: 'unloaded',
                        userId: user.id,
                        userName: user.fullName.isEmpty ? user.email : user.fullName,
                      ),
                      _StorageTab(
                        eventType: 'loaded',
                        userId: user.id,
                        userName: user.fullName.isEmpty ? user.email : user.fullName,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Erreur: $error', style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onglet Déchargé / Chargé
// ─────────────────────────────────────────────────────────────────────────────

class _StorageTab extends ConsumerStatefulWidget {
  const _StorageTab({
    required this.eventType,
    required this.userId,
    required this.userName,
  });

  /// 'unloaded' = camion déchargé au stockage (vient de la mine)
  /// 'loaded'   = camion chargé au stockage (va vers le port)
  final String eventType;
  final String userId;
  final String userName;

  @override
  ConsumerState<_StorageTab> createState() => _StorageTabState();
}

class _StorageTabState extends ConsumerState<_StorageTab> {
  TruckModel? _selectedTruck;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isUnloaded => widget.eventType == 'unloaded';

  Future<void> _confirm(AppLocalizations l10n) async {
    if (_selectedTruck == null) {
      setState(() => _errorMessage = l10n.translate('storage.selectTruck'));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(
          _isUnloaded
              ? l10n.translate('storage.confirmUnload')
              : l10n.translate('storage.confirmLoad'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n
              .translate('storage.confirmMessage')
              .replaceAll('{truck}', _selectedTruck!.immatriculation),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.translate('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _isUnloaded ? AppColors.warning : AppColors.success),
            child: Text(
              _isUnloaded
                  ? l10n.translate('storage.validateUnload')
                  : l10n.translate('storage.validateLoad'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final repo = ref.read(weighingRepositoryProvider);
      await repo.createStorageEvent(
        truckId: _selectedTruck!.id,
        truckImmatriculation: _selectedTruck!.immatriculation,
        fleetId: _selectedTruck!.fleetId,
        recordedBy: widget.userId,
        recordedByName: widget.userName,
        eventType: widget.eventType,
      );

      if (mounted) {
        setState(() {
          _successMessage = _isUnloaded
              ? l10n.translate('storage.unloadSuccess')
              : l10n.translate('storage.loadSuccess');
          _selectedTruck = null;
          _searchQuery = '';
          _searchController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = '${l10n.translate('common.error')}: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trucksAsync = _isUnloaded
        ? ref.watch(trucksInActiveShiftProvider)
        : ref.watch(activeTrucksStreamProvider);

    return trucksAsync.when(
      data: (trucks) {
        final filtered = _searchQuery.isEmpty
            ? trucks
            : trucks.where((t) {
                final q = _searchQuery.toLowerCase();
                return t.immatriculation.toLowerCase().contains(q) ||
                    t.numeroInterneFlotte.toLowerCase().contains(q);
              }).toList();

        return Column(
          children: [
            // Description de l'onglet
            Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: (_isUnloaded ? AppColors.warning : AppColors.success)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: (_isUnloaded ? AppColors.warning : AppColors.success)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isUnloaded ? Iconsax.arrow_down : Iconsax.arrow_up,
                    color: _isUnloaded ? AppColors.warning : AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      _isUnloaded
                          ? l10n.translate('storage.descUnloaded')
                          : l10n.translate('storage.descLoaded'),
                      style: TextStyle(
                        color: _isUnloaded ? AppColors.warning : AppColors.success,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Barre de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n.translate('trucks.searchHint'),
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Messages
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.warning_2, color: AppColors.error, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(_errorMessage!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            if (_successMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.tick_circle, color: AppColors.success, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(_successMessage!,
                            style: const TextStyle(
                                color: AppColors.success, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),

            if (_errorMessage != null || _successMessage != null)
              const SizedBox(height: AppSpacing.md),

            // Liste des camions
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.truck,
                              color: AppColors.textSecondary.withValues(alpha: 0.4),
                              size: 48),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.translate('storage.noTrucksAvailable'),
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final truck = filtered[index];
                        final isSelected = _selectedTruck?.id == truck.id;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedTruck = isSelected ? null : truck;
                            _errorMessage = null;
                            _successMessage = null;
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.surfaceBorder,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.15)
                                        : AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: const Icon(Iconsax.truck,
                                      color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        truck.immatriculation,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (truck.numeroInterneFlotte.isNotEmpty)
                                        Text(
                                          '# ${truck.numeroInterneFlotte}',
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Iconsax.tick_circle,
                                      color: AppColors.primary, size: 22),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Bouton valider
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : () => _confirm(l10n),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isUnloaded ? AppColors.warning : AppColors.success,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(
                          _isUnloaded ? Iconsax.arrow_down : Iconsax.arrow_up,
                          color: Colors.white,
                          size: 20,
                        ),
                  label: Text(
                    _isUnloaded
                        ? l10n.translate('storage.validateUnload')
                        : l10n.translate('storage.validateLoad'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(
        child: Text('${AppLocalizations.of(context).translate('common.error')}: $e',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}
